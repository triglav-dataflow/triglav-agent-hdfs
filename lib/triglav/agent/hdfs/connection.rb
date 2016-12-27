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
      entries = glob_files_recursively(Array(paths))
      if entries.size > 0
        max = entries.first
        entries[1..entries.size].each do |entry|
          max = entry.modification_time > max.modification_time ? entry : max
        end
        max
      else
        []
      end
    end

    private

    # @param [Array of String] path glob patterns
    #
    # @return [Array of org.apache.hadoop.fs.FileStatus] list of files
    def glob_files_recursively(paths)
      # glob_status does not return PathNotFoundException, return nil instead
      file_entries = []
      paths.each do |path|
        namespace = URI.parse(path).host
        fs = get_fs(namespace)
        entries = fs.glob_status(Path.new(path))
        entries.each do |entry|
          file_entries.concat(list_files_recursively(entry, fs))
        end if entries
      end
      file_entries
    end

    def list_files_recursively(entry, fs = nil)
      return [entry] unless entry.is_directory
      fs ||= get_fs(namespace = URI.parse(entry.get_path).host)

      file_entries = []
      entries = fs.list_status(entry.get_path)
      entries.each do |entry|
        file_entries.concat(list_files_recursively(entry))
      end
      file_entries
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
