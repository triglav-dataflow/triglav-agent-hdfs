require "bundler/gem_tasks"

require 'rake/testtask'
desc 'Run test_unit based test'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = Dir["test/**/test_*.rb"]
  t.verbose = false
  t.warning = false
end
task :default => :test
