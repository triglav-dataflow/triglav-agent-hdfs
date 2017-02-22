# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'triglav/agent/hdfs/version'

Gem::Specification.new do |spec|
  spec.name          = "triglav-agent-hdfs"
  spec.version       = Triglav::Agent::Hdfs::VERSION
  spec.authors       = ["Naotoshi Seo"]
  spec.email         = ["sonots@gmail.com"]

  spec.summary       = %q{Triglav Agent for HDFS.}
  spec.description   = %q{Triglav Agent for HDFS.}
  spec.homepage      = "https://github.com/triglav-dataflow/triglav-agent-hdfs"
  spec.license       = "MIT"

  # important to get the jars installed
  spec.platform      = 'java'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.files        += Dir['lib/*.jar']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "triglav-agent"
  spec.add_dependency "triglav_client"

  spec.requirements << "jar org.apache.hadoop:hadoop-client, 2.6.5"

  # memo: development_dependency 'jar-dependencies' does not vendor_jars as default unlike runtime_dependency
  spec.add_development_dependency "jar-dependencies", "~> 0.3.5"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "test-unit-rr"
  spec.add_development_dependency "test-unit-power_assert"
  spec.add_development_dependency "timecop"
end
