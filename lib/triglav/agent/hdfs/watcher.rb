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
      last_modification_time = get_last_modification_time(resource)
      $logger.debug { "Start process #{resource.uri}, last_modification_time:#{last_modification_time}" }
      events, new_last_modification_time = get_events(resource, $setting.debug? ? 0 : last_modification_time)
      $logger.debug { "Finish process #{resource.uri}, last_modification_time:#{last_modification_time}, " \
                      "new_last_modification_time:#{new_last_modification_time}" }
      return if events.nil? || events.empty?
      yield(events) # send_message
      update_status_file(resource, new_last_modification_time)
    end

    def update_status_file(resource, last_modification_time)
      Triglav::Agent::StorageFile.open($setting.status_file) do |fp|
        @status = fp.load # reload during locking
        update_status(resource, last_modification_time)
        fp.dump(@status)
      end
    end

    def update_status(resource, last_modification_time)
      (@status[:last_modification_time] ||= {})[resource.uri.to_sym] = last_modification_time
    end

    def get_last_modification_time(resource)
      unless last_modification_time = @status.dig(:last_modification_time, resource.uri.to_sym)
        last_modification_time = get_current_time
        update_status_file(resource, last_modification_time)
      end
      last_modification_time
    end

    def get_current_time
      (Time.now.to_f * 1000).to_i # msec
    end

    def get_events(resource, last_modification_time)
      ResourceWatcher.new(connection, resource, last_modification_time).get_events
    end

    class ResourceWatcher
      attr_reader :connection, :resource, :last_modification_time

      def initialize(connection, resource, last_modification_time)
        @connection = connection
        @resource = resource
        @last_modification_time = last_modification_time
      end

      # @param [TriglavClient::ResourceResponse] resource
      # resource:
      #   uri: hdfs://host/path
      #   unit: 'daily' or 'hourly', or 'daily,hourly' (send hourly event for hourly resource)
      #   timezone: '+09:00'
      #   span_in_days: 32
      # @param [Ineger] last_modification_time (for debug)
      def get_events
        if !%w[daily hourly daily,hourly].include?(resource.unit) ||
            resource.timezone.nil? || resource.span_in_days.nil?
          $logger.warn { "Broken resource: #{resource.to_s}" }
          return nil
        end

        begin
          latest_files = build_latest_files

          events = build_events(latest_files)
          if resource.unit == 'daily,hourly'
            daily_events = build_daily_events_from_hourly(latest_files)
            events.concat(daily_events)
          end

          new_last_modification_time = latest_modification_time(latest_files)
          [events, new_last_modification_time]
        rescue => e
          $logger.warn { "#{e.class} #{e.message} #{e.backtrace.join("\n  ")}" }
          nil
        end
      end

      private

      # 'daily,hourly': qeury in hourly way, then merge events into daily in ruby
      def query_unit(resource_unit)
        resource_unit == 'daily,hourly' ? 'hourly' : resource_unit
      end

      def build_dates
        now = Time.now.localtime(resource.timezone)
        dates = resource.span_in_days.times.map do |i|
          (now - (i * 86000)).to_date
        end
      end

      def build_paths
        dates = build_dates
        paths = {}
        # If path becomes same, use newer date
        case query_unit(resource.unit)
        when 'hourly'
          dates.each do |date|
            date_time = date.to_time
            (0..23).each do |hour|
              path = (date_time + hour).strftime(resource.uri)
              paths[path] = [date, hour]
            end
          end
        when 'daily'
          hour = 0
          dates.each do |date|
            path = date.strftime(resource.uri)
            paths[path] = [date, hour]
          end
        end
        paths
      end

      def build_latest_files
        paths = build_paths
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
        unit = query_unit(resource.unit)
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
        Time.strptime("#{date.to_s} #{hour.to_i} #{timezone}", '%Y-%m-%d %H %z').to_i
      end
    end
  end
end
