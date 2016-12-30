module CreateFile
  def self.included(klass)
    klass.extend(self)
  end

  def fs
    @fs ||= connection.connection_info.dig(:config, :"fs.defaultFS")
  end

  def directory
    'sandbox/test_triglav_agent_hdfs'
  end

  def data
    now = Time.now
    50.times.map do |i|
      t = now - i * 3600
      {
        d: t.strftime("%Y-%m-%d"),
        h: t.strftime("%H"),
      }
    end
  end

  def create_directory
    connection.mkdir(File.join(fs, directory))
  end

  def create_files
    data.map {|row| row[:d] }.uniq.each do |d|
      connection.mkdir(File.join(fs, directory, d))
    end
    data.each do |row|
      connection.touch(File.join(fs, directory, row[:d], row[:h]), true)
    end
  end

  def delete_directory
    connection.delete(File.join(fs, directory), true)
  end

  def connection
    return @connection if @connection
    connection_info = $setting.dig(:hdfs, :connection_info)[:'hdfs://']
    @connection ||= Triglav::Agent::Hdfs::Connection.new(connection_info)
  end
end
