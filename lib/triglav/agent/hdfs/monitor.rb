require 'triglav/agent/base/monitor'
require 'triglav-agent-hdfs_jars'
require 'triglav/agent/hdfs/connection'
require 'uri'
require 'securerandom'

module Triglav::Agent
  module Hdfs
    class Monitor < Base::Monitor
      attr_reader :connection, :resource_uri_prefix, :resource, :last_modification_times

      # @param [Triglav::Agent::Hdfs::Connection] connection
      # @param [TriglavClient::ResourceResponse] resource
      # resource:
      #   uri: hdfs://host/path
      #   unit: 'daily', 'hourly', or 'singular'
      #   timezone: '+09:00'
      #   span_in_days: 32
      def initialize(connection, resource_uri_prefix, resource)
        @connection = connection
        @resource_uri_prefix = resource_uri_prefix
        @resource = resource
        @status = Triglav::Agent::Status.new(resource_uri_prefix, resource.uri)
        @last_modification_times = get_last_modification_times
      end

      def process
        unless resource_valid?
          $logger.warn { "Broken resource: #{resource.to_s}" }
          return nil
        end
        $logger.debug { "Start process #{resource.uri}" }

        events, new_last_modification_times = get_events

        $logger.debug { "Finish process #{resource.uri}" }

        return nil if events.nil? || events.empty?
        yield(events) if block_given? # send_message
        update_status_file(new_last_modification_times)
        true
      end

      private

      def get_events
        new_last_modification_times = get_new_last_modification_times
        latest_files = select_latest_files(new_last_modification_times)
        events = build_events(latest_files)
        [events, new_last_modification_times]
      rescue => e
        $logger.warn { "#{e.class} #{e.message} #{e.backtrace.join("\n  ")}" }
        nil
      end

      def update_status_file(last_modification_times)
        last_modification_times[:max] = last_modification_times.values.max
        @status.set(last_modification_times)
      end

      def get_last_modification_times
        last_modification_times = @status.get || {}
        max_last_modification_time = last_modification_times[:max] || @status.getsetnx([:max], $setting.debug? ? 0 : get_current_time)
        removes = last_modification_times.keys - paths.keys
        appends = paths.keys - last_modification_times.keys
        removes.each {|path| last_modification_times.delete(path) }
        appends.each {|path| last_modification_times[path] = max_last_modification_time }
        last_modification_times
      end

      def get_current_time
        (Time.now.to_f * 1000).to_i # msec
      end

      def resource_valid?
        self.class.resource_valid?(resource)
      end

      def self.resource_valid?(resource)
        resource_unit_valid?(resource) && !resource.timezone.nil? && !resource.span_in_days.nil?
      end

      # Two or more combinations are not allowed for hdfs because
      # * hourly should have %d, %H
      # * daily should have %d, but not have %H
      # * singualr should not have %d
      # These conditions conflict.
      def self.resource_unit_valid?(resource)
        units = resource.unit.split(',').sort
        return false if units.size >= 2
        # if units.include?('hourly')
        #   return false unless resource.uri.match(/%H/)
        # end
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
          (now - (i * 86400)).to_date
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
              paths[path.to_sym] = [date, hour]
            end
          end
        when 'daily'
          hour = 0
          dates.each do |date|
            path = date.strftime(resource.uri)
            paths[path.to_sym] = [date, hour]
          end
        when 'singular'
          path = resource.uri
          paths[path.to_sym] = [nil, nil]
        end
        @paths = paths
      end

      def get_new_last_modification_times
        new_last_modification_times = {}
        paths.each do |path, date_hour|
          latest_file = connection.get_latest_file_under(path.to_s)
          unless latest_file
            $logger.debug { "get_latest_file_under(\"#{path.to_s}\") #=> does not exist" }
            next
          end
          new_last_modification_times[path.to_sym] = latest_file.modification_time
        end
        new_last_modification_times
      end

      def select_latest_files(new_last_modification_times)
        new_last_modification_times.select do |path, new_last_modification_time|
          is_newer = new_last_modification_time > (last_modification_times[path] || 0)
          $logger.debug { "#{path.to_s} #=> last_modification_time:#{new_last_modification_time}, is_newer:#{is_newer}" }
          is_newer
        end
      end

      def build_events(latest_files)
        latest_files.map do |path, last_modification_time|
          date, hour = date_hour = paths[path]
          {
            uuid: SecureRandom.uuid,
            resource_uri: resource.uri,
            resource_unit: resource.unit,
            resource_time: date_hour_to_i(date, hour, resource.timezone),
            resource_timezone: resource.timezone,
            payload: {path: path.to_s, modification_time: last_modification_time}.to_json, # msec
          }
        end
      end

      def date_hour_to_i(date, hour, timezone)
        return 0 if date.nil?
        Time.strptime("#{date.to_s} #{hour.to_i} #{timezone}", '%Y-%m-%d %H %z').to_i
      end
    end
  end
end
