require 'triglav/agent/hdfs/monitor'
require 'triglav/agent/hdfs/connection'

module Triglav::Agent
  module Hdfs
    module Worker
      # serverengine interface
      def initialize
        @timer = Timer.new
      end

      # serverengine interface
      def reload
        $logger.info { "Worker#reload worker_id:#{worker_id}" }
        $setting.reload
      end

      # serverengine interface
      def run
        $logger.info { "Worker#run worker_id:#{worker_id}" }
        start
        until @stop
          @timer.wait(monitor_interval) { process }
        end
      rescue => e
        # ServerEngine.dump_uncaught_error does not tell me e.class
        $logger.error { "#{e.class} #{e.message} #{e.backtrace.join("\\n")}" } # one line
        raise e
      end

      def process
        $logger.info { "Start Worker#process worker_id:#{worker_id}" }
        api_client = ApiClient.new # renew connection

        count = 0
        # It is possible to seperate agent process by prefixes of resource uris
        resource_uri_prefixes.each do |resource_uri_prefix|
          break if stopped?
          # list_aggregated_resources returns unique resources which we have to monitor
          next unless resources = api_client.list_aggregated_resources(resource_uri_prefix)
          $logger.debug { "resource_uri_prefix:#{resource_uri_prefix} resources.size:#{resources.size}" }
          connection = Connection.new(get_connection_info(resource_uri_prefix))
          resources.each do |resource|
            break if stopped?
            count += 1
            monitor = Monitor.new(connection, resource, last_modification_time: $setting.debug? ? 0 : nil)
            monitor.process {|events| api_client.send_messages(events) }
          end
        end
        $logger.info { "Finish Worker#process worker_id:#{worker_id} count:#{count}" }
      end

      def start
        @timer.start
        @stop = false
      end

      # serverengine interface
      def stop
        $logger.info { "Worker#stop worker_id:#{worker_id}" }
        @stop = true
        @timer.stop
      end

      def stopped?
        @stop
      end

      private

      def monitor_interval
        $setting.dig(:hdfs, :monitor_interval) || 60
      end

      def resource_uri_prefixes
        $setting.dig(:hdfs, :connection_info).keys
      end

      def get_connection_info(resource_uri_prefix)
        $setting.dig(:hdfs, :connection_info)[resource_uri_prefix]
      end
    end
  end
end
