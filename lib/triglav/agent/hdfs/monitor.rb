require 'triglav/agent/hdfs/connection'
require 'jbundler'
require 'uri'

module Triglav::Agent::Hdfs
  class Monitor
    attr_reader :connection, :resource, :last_modification_time

    # @param [Triglav::Agent::Hdfs::Connection] connection
    # @param [TriglavClient::ResourceResponse] resource
    # resource:
    #   uri: hdfs://host/path
    #   unit: 'daily' or 'hourly', or 'daily,hourly' (send hourly event for hourly resource)
    #   timezone: '+09:00'
    #   span_in_days: 32
    # @param [Integer] last_modification_time (for debug)
    def initialize(connection, resource, last_modification_time: nil)
      @connection = connection
      @resource = resource
      @last_modification_time = last_modification_time || get_last_modification_time
    end

    def process
      unless resource_valid?
        $logger.warn { "Broken resource: #{resource.to_s}" }
        return nil
      end

      $logger.debug { "Start process #{resource.uri}, last_modification_time:#{last_modification_time}" }
      events, new_last_modification_time = get_events
      $logger.debug { "Finish process #{resource.uri}, last_modification_time:#{last_modification_time}, " \
                      "new_last_modification_time:#{new_last_modification_time}" }

      return nil if events.nil? || events.empty?
      yield(events) # send_message
      update_status_file(new_last_modification_time)
      true
    end

    def get_events
      latest_files = fetch_latest_files

      events = build_events(latest_files)
      if hourly? and daily?
        daily_events = build_daily_events_from_hourly(latest_files)
        events.concat(daily_events)
      end

      new_last_modification_time = latest_modification_time(latest_files)
      [events, new_last_modification_time]
    rescue => e
      $logger.warn { "#{e.class} #{e.message} #{e.backtrace.join("\n  ")}" }
      nil
    end

    private

    def update_status_file(last_modification_time)
      Triglav::Agent::StorageFile.set(
        $setting.status_file,
        [:last_modification_time, resource.uri.to_sym],
        last_modification_time
      )
    end

    def get_last_modification_time
      Triglav::Agent::StorageFile.getsetnx(
        $setting.status_file,
        [:last_modification_time, resource.uri.to_sym],
        get_current_time
      )
    end

    def get_current_time
      (Time.now.to_f * 1000).to_i # msec
    end

    def resource_valid?
      resource_unit_valid? && !resource.timezone.nil? && !resource.span_in_days.nil?
    end

    # singular,daily,hourly is not allowed
    # singular: uri should not have date format
    # daily,hourly: uri should have date format
    def resource_unit_valid?
      units = resource.unit.split(',').sort
      return false if units == ['daily', 'hourly', 'singular']
      if units.include?('hourly')
        return false unless resource.uri.match(/%H/)
      end
      if units.include?('daily')
        return false unless resource.uri.match(/%d/)
      end
      if units.include?('singular')
        return false if resource.uri.match(/%[YmdH]/)
      end
      true
    end

    def hourly?
      return @is_hourly unless @is_hourly.nil?
      @is_hourly = resource.unit.include?('hourly')
    end

    def daily?
      return @is_daily unless @is_daily.nil?
      @is_daily = resource.unit.include?('daily')
    end

    def singular?
      return @is_singular unless @is_singular.nil?
      @is_singular = resource.unit.include?('singular')
    end

    def periodic?
      hourly? or daily?
    end

    def query_unit
      @query_unit ||=
        if hourly?
          'hourly'
        elsif daily?
          'daily'
        elsif singular?
          'singular'
        end
    end

    def dates
      return @dates if @dates
      now = Time.now.localtime(resource.timezone)
      @dates = resource.span_in_days.times.map do |i|
        (now - (i * 86000)).to_date
      end
    end

    def paths
      return @paths if @paths
      paths = {}
      # If path becomes same, use newer date
      case query_unit
      when 'hourly'
        dates.each do |date|
          date_time = date.to_time
          (0..23).each do |hour|
            path = (date_time + hour * 3600).strftime(resource.uri)
            paths[path] = [date, hour]
          end
        end
      when 'daily'
        hour = 0
        dates.each do |date|
          path = date.strftime(resource.uri)
          paths[path] = [date, hour]
        end
      when 'singular'
        path = resource.uri
        paths[path] = [nil, nil]
      end
      @paths = paths
    end

    def fetch_latest_files
      latest_files = {}
      paths.each do |path, date_hour|
        file = connection.get_latest_file_under(path)
        unless file
          $logger.debug { "get_latest_file_under(#{path.inspect}) #=> does not exist" }
          next
        end
        is_newer = file.modification_time > last_modification_time
        $logger.debug { "get_latest_file_under(#{path.inspect}) #=> latest_modification_time:#{file.modification_time}, is_newer:#{is_newer}" }
        next unless is_newer
        date, hour = date_hour
        latest_files[date] ||= {}
        latest_files[date][hour] = file
      end
      latest_files
    end

    def latest_modification_time(latest_files)
      latest_files.values.map do |hourly_latest_files|
        hourly_latest_files.values.map do |file|
          file.modification_time
        end.max
      end.max || last_modification_time
    end

    def build_events(latest_files)
      events = []
      latest_files.map do |date, hourly_latest_files|
        hourly_events = hourly_latest_files.map do |hour, latest_file|
          {
            resource_uri: resource.uri,
            resource_unit: query_unit,
            resource_time: date_hour_to_i(date, hour, resource.timezone),
            resource_timezone: resource.timezone,
            payload: {path: latest_file.path.to_s, modification_time: latest_file.modification_time}.to_json, # msec
          }
        end
        events.concat(hourly_events)
      end
      events
    end

    def build_daily_events_from_hourly(latest_files)
      daily_latest_files = {}
      latest_files.each do |date, hourly_latest_files|
        latest_files = hourly_latest_files.values
        max = latest_files.first
        latest_files[1..latest_files.size].each do |entry|
          max = entry.modification_time > max.modification_time ? entry : max
        end
        daily_latest_files[date] = max
      end
      daily_events = daily_latest_files.map do |date, latest_file|
        {
          resource_uri: resource.uri,
          resource_unit: 'daily',
          resource_time: date_hour_to_i(date, 0, resource.timezone),
          resource_timezone: resource.timezone,
          payload: {path: latest_file.path.to_s, modification_time: latest_file.modification_time}, # msec
        }
      end
    end

    def date_hour_to_i(date, hour, timezone)
      return 0 if date.nil?
      Time.strptime("#{date.to_s} #{hour.to_i} #{timezone}", '%Y-%m-%d %H %z').to_i
    end
  end
end
