# frozen_string_literal: true

require_relative 'helper'
require 'triglav/agent/hdfs/monitor'
require_relative 'support/create_file'

# This test requires a real connection to hdfs, now
# Configure .env to set proper connection_info of test/config.yml
#
# TRIGLAV_URL=http://localhost:7800
# TRIGLAV_USERNAME=triglav_test
# TRIGLAV_PASSWORD=triglav_test
# HDFS_HOST=hdfs
# HDFS_PORT=5433
if File.exist?(File.join(ROOT, '.env'))
  class TestMonitor < Test::Unit::TestCase
    include CreateFile
    Monitor = Triglav::Agent::Hdfs::Monitor

    class << self
      def startup
        Timecop.travel(Time.parse("2016-12-30 23:00:00 +09:00"))
        create_directory
        create_files
      end

      def shutdown
        delete_directory
        Timecop.return
      end
    end

    def build_resource(params = {})
      unit = params[:unit] || 'daily'
      uri =
        case unit
        when /hourly/
          "#{fs}/#{directory}/%Y-%m-%d/%H"
        when /daily/
          "#{fs}/#{directory}/%Y-%m-%d"
        when /singular/
          "#{fs}/#{directory}"
        end
      TriglavClient::ResourceResponse.new({
        uri: uri,
        unit: unit,
        timezone: '+09:00',
        span_in_days: 2,
        consumable: true,
        notifiable: false,
      }.merge(params))
    end

    def test_resource_valid
      resource = build_resource(unit: 'singular,daily,hourly')
      assert { Monitor.resource_valid?(resource) == false }

      resource = build_resource(unit: 'daily,hourly')
      assert { Monitor.resource_valid?(resource) == false }

      resource = build_resource(unit: 'hourly', uri: "#{fs}/#{directory}/%Y-%m-%d")
      assert { Monitor.resource_valid?(resource) == false }

      # resource = build_resource(unit: 'daily', uri: "#{fs}/#{directory}/%Y-%m")
      # assert { Monitor.resource_valid?(resource) == false }

      resource = build_resource(unit: 'singular', uri: "#{fs}/#{directory}/%Y-%m-%d")
      assert { Monitor.resource_valid?(resource) == false }
    end

    def test_process
      resource = build_resource
      monitor = Monitor.new(connection, resource)
      assert_nothing_raised { monitor.process }
    end

    def test_get_hourly_events
      resource = build_resource(unit: 'hourly')
      monitor = Monitor.new(connection, resource)
      success = monitor.process do |events|
        assert { events != nil}
        assert { events.size == resource.span_in_days * 24 }
        event = events.first
        assert { event.keys == %i[uuid resource_uri resource_unit resource_time resource_timezone payload] }
        assert { event[:resource_uri] == resource.uri }
        assert { event[:resource_unit] == resource.unit }
        assert { event[:resource_timezone] == resource.timezone }
      end
      assert { success }
    end

    def test_get_daily_events
      resource = build_resource(unit: 'daily')
      monitor = Monitor.new(connection, resource)
      success = monitor.process do |events|
        assert { events != nil}
        assert { events.size == resource.span_in_days }
        event = events.first
        assert { event.keys == %i[uuid resource_uri resource_unit resource_time resource_timezone payload] }
        assert { event[:resource_uri] == resource.uri }
        assert { event[:resource_unit] == resource.unit }
        assert { event[:resource_timezone] == resource.timezone }
      end
      assert { success }
    end

    def test_get_singular_events
      resource = build_resource(unit: 'singular')
      monitor = Monitor.new(connection, resource)
      success = monitor.process do |events|
        assert { events != nil}
        assert { events.size == 1 }
        event = events.first
        assert { event.keys == %i[uuid resource_uri resource_unit resource_time resource_timezone payload] }
        assert { event[:resource_uri] == resource.uri }
        assert { event[:resource_unit] == resource.unit }
        assert { event[:resource_timezone] == resource.timezone }
      end
      assert { success }
    end
  end
end
