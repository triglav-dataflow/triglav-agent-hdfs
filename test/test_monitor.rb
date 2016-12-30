# frozen_string_literal: true

require_relative 'helper'
require 'triglav/agent/hdfs/monitor'

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

    def test_resource_unit_valid
      resource = build_resource(unit: 'singular,daily,hourly')
      monitor = Triglav::Agent::Hdfs::Monitor.new(connection, resource, last_modification_time: 0)
      assert { monitor.send(:resource_unit_valid?) == false }

      resource = build_resource(unit: 'hourly', uri: "#{fs}/#{directory}/%Y-%m-%d")
      monitor = Triglav::Agent::Hdfs::Monitor.new(connection, resource, last_modification_time: 0)
      assert { monitor.send(:resource_unit_valid?) == false }

      resource = build_resource(unit: 'daily', uri: "#{fs}/#{directory}/%Y-%m")
      monitor = Triglav::Agent::Hdfs::Monitor.new(connection, resource, last_modification_time: 0)
      assert { monitor.send(:resource_unit_valid?) == false }

      resource = build_resource(unit: 'singular', uri: "#{fs}/#{directory}/%Y-%m-%d")
      monitor = Triglav::Agent::Hdfs::Monitor.new(connection, resource, last_modification_time: 0)
      assert { monitor.send(:resource_unit_valid?) == false }
    end

    def test_process
      resource = build_resource
      monitor = Triglav::Agent::Hdfs::Monitor.new(connection, resource)
      assert_nothing_raised { monitor.process }
    end

    def test_get_hourly_events
      resource = build_resource(unit: 'hourly')
      monitor = Triglav::Agent::Hdfs::Monitor.new(connection, resource, last_modification_time: 0)
      success = monitor.process do |events|
        assert { events != nil}
        assert { events.size == resource.span_in_days * 24 }
        event = events.first
        assert { event.keys == %i[resource_uri resource_unit resource_time resource_timezone payload] }
        assert { event[:resource_uri] == resource.uri }
        assert { event[:resource_unit] == resource.unit }
        assert { event[:resource_timezone] == resource.timezone }
      end
      assert { success }
    end

    def test_get_daily_events
      resource = build_resource(unit: 'daily')
      monitor = Triglav::Agent::Hdfs::Monitor.new(connection, resource, last_modification_time: 0)
      success = monitor.process do |events|
        assert { events != nil}
        assert { events.size == resource.span_in_days }
        event = events.first
        assert { event.keys == %i[resource_uri resource_unit resource_time resource_timezone payload] }
        assert { event[:resource_uri] == resource.uri }
        assert { event[:resource_unit] == resource.unit }
        assert { event[:resource_timezone] == resource.timezone }
      end
      assert { success }
    end

    def test_get_singular_events
      resource = build_resource(unit: 'singular')
      monitor = Triglav::Agent::Hdfs::Monitor.new(connection, resource, last_modification_time: 0)
      success = monitor.process do |events|
        assert { events != nil}
        assert { events.size == 1 }
        event = events.first
        assert { event.keys == %i[resource_uri resource_unit resource_time resource_timezone payload] }
        assert { event[:resource_uri] == resource.uri }
        assert { event[:resource_unit] == resource.unit }
        assert { event[:resource_timezone] == resource.timezone }
      end
      assert { success }
    end

    def test_get_daily_hourly_events
      resource = build_resource(unit: 'daily,hourly')
      monitor = Triglav::Agent::Hdfs::Monitor.new(connection, resource, last_modification_time: 0)
      success = monitor.process do |events|
        assert { events != nil}
        assert { events.size == resource.span_in_days * 24 + resource.span_in_days }
        assert { events.first[:resource_unit] == 'hourly' }
        assert { events.last[:resource_unit] == 'daily' }
      end
      assert { success }
    end
  end
end