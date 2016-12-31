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

      $logger.debug {
        "Start process #{resource.uri}, " \
        "last_modification_time:#{last_modification_time}"
      }

      events, new_last_modification_time = get_events

      $logger.debug {
        "Finish process #{resource.uri}, " \
        "last_modification_time:#{last_modification_time}, " \
        "new_last_modification_time:#{new_last_modification_time}"
      }

      return nil if events.nil? || events.empty?
      yield(events) # send_message
      update_status_file(new_last_modification_time)
      true
    end

    private

    def get_events
      latest_files = fetch_latest_files
      events = build_events(latest_files)
      new_last_modification_time = latest_modification_time(latest_files)
      [events, new_last_modification_time]
    rescue => e
      $logger.warn { "#{e.class} #{e.message} #{e.backtrace.join("\n  ")}" }
      nil
    end

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

    # Two or more combinations are not allowed for hdfs because
    # * hourly should have %d, %H
    # * daily should have %d, but not have %H
    # * singualr should not have %d
    # These conditions conflict.
    def resource_unit_valid?
      units = resource.unit.split(',').sort
      return false if units.size >= 2
      if units.include?('hourly')
        return false unless resource.uri.match(/%H/)
      end
      # if units.include?('daily')
      #   return false unless resource.uri.match(/%d/)
      # end
      if units.include?('singular')
        return false if resource.uri.match(/%[YmdH]/)
      end
      true
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
      case resource.unit
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
        latest_files[date_hour] = file
      end
      latest_files
    end

    def latest_modification_time(latest_files)
      latest_files.values.map do |file|
        file.modification_time
      end.max || last_modification_time
    end

    def build_events(latest_files)
      latest_files.map do |date_hour, file|
        date, hour = date_hour
        {
          resource_uri: resource.uri,
          resource_unit: resource.unit,
          resource_time: date_hour_to_i(date, hour, resource.timezone),
          resource_timezone: resource.timezone,
          payload: {path: file.path.to_s, modification_time: file.modification_time}.to_json, # msec
        }
      end
    end

    def date_hour_to_i(date, hour, timezone)
      return 0 if date.nil?
      Time.strptime("#{date.to_s} #{hour.to_i} #{timezone}", '%Y-%m-%d %H %z').to_i
    end
  end
end
