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

task :vendor_jars => ["clean_jars"] do
  require 'jars/installer'
  Jars::Installer.vendor_jars!
end
task :clean_jars do
  require 'fileutils'
  Dir['lib/*'].reject {|_| _.include?('triglav') }.each {|_| FileUtils.rm_r(_) }
end

task :release => ["vendor_jars"]
