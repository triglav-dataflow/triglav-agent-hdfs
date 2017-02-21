module StubMonitor
  def self.included(klass)
    klass.extend(self)
  end

  def stub_monitor
    stub.proxy(Triglav::Agent::Hdfs::Monitor).new do |obj|
      stub(obj).process.yields([dummy_event]) {}
    end
  end

  def stub_error_monitor
    stub.proxy(Triglav::Agent::Hdfs::Monitor).new do |obj|
      stub(obj).process { raise 'error' }
    end
  end

  def dummy_event
    TriglavClient::MessageRequest.new(
      resource_uri: 'hdfs://hdev/sandbox/test_triglav_agent_hdfs',
      resource_unit: 'daily',
      resource_timezone: '+09:00',
      resource_time: 1487602800
    )
  end
end
