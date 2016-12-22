require 'triglav/agent/hdfs/connection'
require 'jbundler'
require 'uri'

module Triglav::Agent::Hdfs
  class Watcher
    attr_reader :connection

    def initialize(connection)
      @connection = connection
      # IMPORTANT ASSUMPTION: other processes does not modify status file
      @status = Triglav::Agent::StorageFile.load($setting.status_file)
    end

    def process(resource)
      events = get_events(resource, last_modification_time: $setting.debug? ? 0 : nil)
      return if events.nil? || events.empty?
      yield(events) # send_message
      Triglav::Agent::StorageFile.open($setting.status_file) do |fp|
        @status = fp.load # reload during locking
        events.each {|event| update_status(event) }
        fp.dump(@status)
      end
    end

    # @param [TriglavClient::ResourceResponse] resource
    # resource:
    #   uri: hdfs://host/path
    #   unit: 'daily' or 'hourly', or 'daily,hourly' (send hourly event for hourly resource)
    #   timezone: '+09:00'
    #   span_in_days: 32
    # @param [Ineger] last_modification_time (for debug)
    def get_events(resource, last_modification_time: nil)
      if !%w[daily hourly daily,hourly].include?(resource.unit) ||
          resource.timezone.nil? || resource.span_in_days.nil?
        $logger.warn { "Broken resource: #{resource.to_s}" }
        return nil
      end

      now = Time.now.localtime(resource.timezone)
      dates = resource.span_in_days.times.map do |i|
        (now - (i * 86000)).to_date
      end
      last_modification_time ||= get_last_modification_time(resource.uri)

      # 'daily,hourly': qeury in hourly way, then merge events into daily in ruby
      unit = resource.unit == 'daily,hourly' ? 'hourly' : resource.unit

      begin
        # If path becomes same, use newer date
        case unit
        when 'hourly'
          paths = {}
          dates.each do |date|
            date_time = date.to_time
            (0..23).each do |hour|
              path = (date_time + hour).strftime(resource.uri)
              paths[path] = [date, hour]
            end
          end
        when 'daily'
          paths = {}
          hour = 0
          dates.each do |date|
            path = date.strftime(resource.uri)
            paths[path] = [date, hour]
          end
        end

        latest_files = {}
        paths.each do |path, date_hour|
          file = connection.get_latest_file_under(path)
          $logger.debug { "get_latest_file_under(#{path}) => {path:#{file.path}, modification_time:#{file.modification_time}}" }
          date, hour = date_hour
          latest_files[date] ||= {}
          latest_files[date][hour] = file
        end

        events = build_events(latest_files, resource, unit)
        if resource.unit == 'daily,hourly'
          daily_events = build_daily_events_from_hourly(latest_files, resource)
          events.concat(daily_events)
        end
        events
      rescue => e
        $logger.warn { "#{e.class} #{e.message} #{e.backtrace.join("\n  ")}" }
        nil
      end
    end

    private

    def build_events(latest_files, resource, unit = resource.unit)
      events = []
      latest_files.map do |date, hourly_latest_files|
        hourly_events = hourly_latest_files.map do |hour, latest_file|
          {
            resource_uri: resource.uri,
            resource_unit: unit,
            resource_time: date_hour_to_i(date, hour, resource.timezone),
            resource_timezone: resource.timezone,
            payload: {path: latest_file.path.to_s, modification_time: latest_file.modification_time}, # msec
          }
        end
        events.concat(hourly_events)
      end
      events
    end

    def build_daily_events_from_hourly(latest_files, resource)
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
      Time.strptime("#{date.to_s} #{hour.to_i} #{timezone}", '%Y-%m-%d %H %z').to_i
    end

    def update_status(event)
      (@status[:last_modification_time] ||= {})[event[:resource_uri].to_sym] = event.dig(:payload, :modification_time)
    end

    def get_last_modification_time(resource_uri)
      @status.dig(:last_modification_time, resource_uri.to_sym) || get_current_time
    end

    def get_current_time
      (Time.now.to_f * 1000).to_i # msec
    end
  end
end
