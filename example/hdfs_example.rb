require 'jbundler'

uri = 'hdfs://10.66.40.24:8020/user/anonymous'
last_read_txid = 0

Configuration = org.apache.hadoop.conf.Configuration
Path = org.apache.hadoop.fs.Path
DistributedFileSystem = org.apache.hadoop.hdfs.DistributedFileSystem
PathFilter = org.apache.hadoop.fs.PathFilter

# public class RegexExcludePathFilter implements PathFilter {
#     private final String regex;
# 
#     public RegexExcludePathFilter(String regex) {
#         this.regex = regex;
#     }
# 
#     public boolean accept(Path path) {
#         return !path.toString().matches(regex);
#     }
# }

path = Path.new(uri)
conf = Configuration.new
# fs = path.get_file_system(conf) # this does not allow to specify doas 'hadoop', use below instead
fs = DistributedFileSystem.get(path.get_file_system(conf).get_uri, conf, 'hadoop')

status = fs.get_file_status(path)
puts "get_file_status(#{path})"
puts "  #{status.path} #{status.is_directory} #{status.modification_time}"

# list_status lists up files (including directories) under a directory, but does not traverse recursively
puts "list_status(#{path})"
entries = fs.list_status(path)
entries.each do |entry|
  puts "  #{entry.path} #{entry.is_directory} #{entry.modification_time}"
end

# list_files allows us to traverse recursively, but does not list up directories
puts "list_files(#{path}, true)"
files = fs.list_files(path, true)
while files.has_next
  status = files.next
  puts "  #{status.get_path} #{status.is_directory} #{status.get_modification_time}"
end

path = Path.new('hdfs://10.66.40.24:8020/user/anonymous/*/*')
fs = DistributedFileSystem.get(java.net.URI.new('hdfs://10.66.40.24:8020'), conf, 'hadoop')
puts "glob_status(#{path})"
entries = fs.glob_status(path)
entries.each do |entry|
  puts "  #{entry.path} #{entry.is_directory} #{entry.modification_time}"
end

def glob_files_recursively(fs, path)
  # glob_status does not return PathNotFoundException, return nil instead
  entries = fs.glob_status(path)
  return nil if entries.nil?

  file_entries = []
  entries.each do |entry|
    file_entries.concat(list_files_recursively(fs, entry))
  end

  file_entries
end

def list_files_recursively(fs, entry)
  return [entry] unless entry.is_directory

  file_entries = []
  entries = fs.list_status(entry.get_path)
  entries.each do |entry|
    file_entries.concat(list_files_recursively(fs, entry))
  end
  file_entries
end

path = Path.new('hdfs://10.66.40.24:8020/user/anonymous/*/*')
fs = DistributedFileSystem.get(path.get_file_system(conf).get_uri, conf, 'hadoop')
puts "glob_files_recursively(#{path})"
entries = glob_files_recursively(fs, path)
entries.each do |entry|
  puts "  #{entry.path} #{entry.is_directory} #{entry.modification_time}"
end
