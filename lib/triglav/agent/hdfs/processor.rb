require 'triglav/agent/base/processor'

module Triglav::Agent
  module Hdfs
    class Processor < Base::Processor
      def process
        before_process
        success_count = 0
        consecutive_error_count = 0
        Parallel.each(resources, parallel_opts) do |resource|
          raise Parallel::Break if stopped?
          events = nil
          new_resource_statuses = nil
          begin
            @connection_pool.with do |connection|
              resource_statuses = get_resource_statuses(resource)
              monitor = monitor_class.new(
                connection, resource_uri_prefix, resource, resource_statuses
              )
              events, new_resource_statuses = monitor.process
            end
            if events
              $logger.info { "send_messages:#{events.map(&:to_hash).to_json}" }
              @api_client_pool.with {|api_client| api_client.send_messages(events) }
            end
            @mutex.synchronize do
              set_resource_statuses(new_resource_statuses, resource) if new_resource_statuses
              success_count += 1
              consecutive_error_count = 0
            end
          rescue => e
            log_error(e)
            $logger.info { "failed_events:#{events.map(&:to_hash).to_json}" } if events
            @mutex.synchronize do
              raise TooManyError if (consecutive_error_count += 1) > self.class.max_consecuitive_error_count
            end
          end
        end
        success_count
      ensure
        after_process
      end

      private

      def before_process
        super
        started = Time.now
        @resource_uri_prefix_statuses = Triglav::Agent::Status.new(resource_uri_prefix).get
        elapsed = Time.now - started
        $logger.info { "Read status #{resource_uri_prefix} #{elapsed.to_f}sec" }
        @started = Time.now
        $logger.info { "Start  Processor#process #{resource_uri_prefix}" }
      end

      def after_process
        super
        elapsed = Time.now - @started
        $logger.info { "Finish Processor#process #{resource_uri_prefix} elapsed:#{elapsed.to_f}" }
      end

      def get_resource_statuses(resource)
        resource_statuses = @resource_uri_prefix_statuses[resource.uri.to_sym]
      end

      def set_resource_statuses(resource_statuses, resource)
        started = Time.now
        resource_status = Triglav::Agent::Status.new(resource_uri_prefix, resource.uri)
        resource_status.set(resource_statuses)
        elapsed = Time.now - started
        $logger.info { "Store status resource:#{resource.uri} #{elapsed.to_f}sec" }
      end
    end
  end
end
