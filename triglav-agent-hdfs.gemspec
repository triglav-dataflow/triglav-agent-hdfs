# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'triglav/agent/hdfs/version'

Gem::Specification.new do |spec|
  spec.name          = "triglav-agent-hdfs"
  spec.version       = Triglav::Agent::Hdfs::VERSION
  spec.authors       = ["Triglav Team"]
  spec.email         = ["triglav_admin_my@dena.jp"]

  spec.summary       = %q{HDFS agent for triglav, data-driven workflow tool.}
  spec.description   = %q{HDFS agent for triglav, data-driven workflow tool.}
  spec.homepage      = "https://github.com/triglav-dataflow/triglav-agent-hdfs"
  spec.license       = "MIT"

  # important to get the jars installed
  spec.platform      = 'java'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.files        += Dir['lib/*.jar']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # ENV is for travis
  spec.add_dependency "jar-dependencies", ENV['JAR_DEPENDENCIES_VERSION'] ? "= #{ENV['JAR_DEPENDENCIES_VERSION']}" : "~> 0.3.5"
  spec.add_dependency "triglav-agent"
  spec.add_dependency "triglav_client"
  spec.add_dependency "parallel"
  spec.add_dependency "connection_pool"

  spec.requirements << "jar org.apache.hadoop:hadoop-client, 2.6.5"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "test-unit-rr"
  spec.add_development_dependency "test-unit-power_assert"
  spec.add_development_dependency "timecop"
end
