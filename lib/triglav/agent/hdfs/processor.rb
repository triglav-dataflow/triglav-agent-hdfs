require 'triglav/agent/base/processor'

module Triglav::Agent
  module Hdfs
    class Processor < Base::Processor
      def process
        before_process
        Parallel.each(resources, parallel_opts) do |resource|
          raise Parallel::Break if stopped?
          begin
            main_process(resource)
          rescue => e
            error_process(resource)
          end
        end
        return_process
      ensure
        ensure_process
      end

      private

      def before_process
        @started = Time.now
        $logger.info { "Start  Processor#process #{resource_uri_prefix}" }

        super

        @success_count = 0
        @consecutive_error_count = 0

        @status = Triglav::Agent::Status.new(resource_uri_prefix)
        started = Time.now
        @resource_uri_prefix_statuses = @status.get
        elapsed = Time.now - started
        $logger.info { "Read status #{resource_uri_prefix} #{elapsed.to_f}sec" }

        resources.each do |resource|
          resource_statuses = @resource_uri_prefix_statuses[resource.uri.to_sym]
          resource_statuses[:max] ||= @status.getsetnx(
            [resource.uri.to_sym, :max],
            $setting.debug? 0 : get_current_time
          )
        end
      end

      def main_process(resource)

        events = nil
        new_resource_statuses = nil
        begin
          @connection_pool.with do |connection|
            resource_statuses = @resource_uri_prefix_statuses[resource.uri.to_sym]
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
            if new_resource_statuses
              @resource_uri_prefix_statuses[resource.uri.to_sym] = new_resource_statuses
              started = Time.now
              @status.set(@resource_uri_prefix_statuses)
              elapsed = Time.now - started
              $logger.info { "Store status resource:#{resource.uri} #{elapsed.to_f}sec" }
            end
          end
        rescue => e
          log_error(e)
          $logger.info { "failed_events:#{events.map(&:to_hash).to_json}" } if events
          raise e
        end
      end

      def return_process
        @success_count
      end

      def error_process(resource)
        @mutex.synchronize do
          consecutive_error_count += 1
        end
        if consecutive_error_count > self.class.max_consecuitive_error_count
          raise TooManyError
        end
      end

      def after_process
        super
        elapsed = Time.now - @started
        $logger.info { "Finish Processor#process #{resource_uri_prefix} elapsed:#{elapsed.to_f}" }
      end

      def get_current_time
        (Time.now.to_f * 1000).to_i # msec
      end
    end
  end
end
