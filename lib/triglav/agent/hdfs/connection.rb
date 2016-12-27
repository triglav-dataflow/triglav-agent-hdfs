require 'jbundler'
require 'uri'

module Triglav::Agent::Hdfs
  class Connection
    Path = org.apache.hadoop.fs.Path
    DistributedFileSystem = org.apache.hadoop.hdfs.DistributedFileSystem
    PathFilter = org.apache.hadoop.fs.PathFilter
    FileSystem = org.apache.hadoop.fs.FileSystem

    attr_reader :connection_info

    # @param [Hash] connection_info
    # @option connection_info [Array] :config_files config files for org.apache.hadoop.conf.Configuration
    # @option connection_info [Hash] :config config key value parameters for org.apache.hadoop.conf.Configuration
    # @option connection_info [String] :doas
    def initialize(connection_info)
      @connection_info = connection_info
      @configurations = {}
      @filesystems = {}
    end

    # Get latest modification file under given path
    #
    # @param [Array of String, or String] path glob patterns
    #
    # @return [org.apache.hadoop.fs.FileStatus]
    def get_latest_file_under(paths)
      entries = []
      Array(paths).each do |path|
        entries.concat(glob_files_recursively(path))
      end

      latest_entry = nil
      if entries.size > 0
        latest_entry = entries.first
        entries[1..entries.size].each do |entry|
          latest_entry = entry.modification_time > latest_entry.modification_time ? entry : latest_entry
        end
      end
      latest_entry
    end

    private

    # @param [String] path glob patterns
    #
    # @return [Array of org.apache.hadoop.fs.FileStatus] list of files
    def glob_files_recursively(path, fs = nil)
      fs ||= get_fs(namespace = URI.parse(path).host)

      entries = []
      glob_entries = fs.glob_status(Path.new(path))
      glob_entries.each do |entry|
        entries.concat(list_files_recursively(entry, fs))
      end if glob_entries
      entries
    end

    def list_files_recursively(entry, fs = nil)
      return [entry] unless entry.is_directory
      fs ||= get_fs(namespace = URI.parse(entry.get_path).host)

      entries = []
      list_entries = fs.list_status(entry.get_path)
      list_entries.each do |entry|
        entries.concat(list_files_recursively(entry, fs))
      end
      entries
    end

    def get_configuration(namespace)
      return @configurations[namespace] if @configurations[namespace]

      configuration = org.apache.hadoop.conf.Configuration.new

      (connection_info[:config_files] || []).each do |config_file|
        configuration.add_resource(config_file)
      end
      configuration.reload_configuration

      (connection_info[:config] || {}).each do |key, value|
        configuration.set(key.to_s, value.to_s)
      end

      configuration.set('fs.defaultFS', "hdfs://#{namespace}")

      @configurations[namespace] = configuration
    end

    def get_fs(namespace)
      return @filesystems[namespace] if @filesystems[namespace]
      configuration = get_configuration(namespace)
      if doas = connection_info[:doas]
        uri = FileSystem.get_default_uri(configuration)
        fs = FileSystem.get(uri, configuration, doas)
      else
        fs = FileSystem.get(configuration)
      end
      @filesystems[namespace] = fs
    end
  end
end
