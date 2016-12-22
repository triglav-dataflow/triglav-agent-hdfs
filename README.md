# Triglav::Agent::Hdfs

Triglav Agent for Hdfs

## Requirements

* JRuby >= 9.1.5.0
* Java >= 1.8.0_45

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'triglav-agent-hdfs'
```

And then execute:

    $ bundle
    $ bundle exec jbundle install

Or install it yourself as:

    $ gem install triglav-agent-hdfs
    $ jbundle install

## CLI

```
Usage: triglav-agent-hdfs [options]
    -c, --config VALUE               Config file (default: config.yml)
    -s, --status VALUE               Status stroage file (default: status.yml)
    -t, --token VALUE                Triglav access token storage file (default: token.yml)
        --dotenv                     Load environment variables from .env file (default: false)
    -h, --help                       help
        --log VALUE                  Log path (default: STDOUT)
        --log-level VALUE            Log level (default: info)
```

Run as:

```
bundle exec triglav-agent-hdfs --dotenv -c config.yml
```

## Configuration

Prepare config.yml as:

```yaml
serverengine:
  log: 'STDOUT'
  log_level: 'debug'
  log_rotate_age: 5
  log_rotate_size: 10485760
triglav:
  url: <%= ENV['TRIGLAV_URL'] %>
  credential:
    name: <%= ENV['TRIGLAV_USERNAME'] %>
    password: <%= ENV['TRIGLAV_PASSWORD'] %>
    authenticator: local
hdfs:
  watcher_interval: 60
  connection_info:
    "hdfs://":
      config_files:
        - /etc/hadoop/conf/core-site.xml
        - /etc/hadoop/conf/hdfs-site.xml
      config:
        fs.defaultFS: 'hdfs://10.66.40.24:8020'
        dfs.replication: 1
        fs.hdfs.impl: 'org.apache.hadoop.hdfs.DistributedFileSystem'
        fs.file.impl: 'org.apache.hadoop.fs.LocalFileSystem'
      doas: hadoop
```

You can use erb template. You may load environment variables from .env file with `--dotenv` option.

### serverengine section

You can specify any [serverengine](https://github.com/fluent/serverengine) options at this section

### triglav section

Specify triglav api url, and a credential to authenticate.

The access token obtained is stored into a token storage file (--token option).

### hdfs section

This section is the special section for triglav-agent-hdfs.

* **watcher_interval**: The interval to watch tables (number, default: 60)
* **connection_info**: key-value pairs of hdfs connection info where keys are resource URI pattern in regular expression, and values are connection information

## How it behaves

1. Authenticate with triglav
  * Store the access token into the token storage file
  * Read the token from the token storage file next time
  * Refresh the access token if it is expired
2. Repeat followings in `watcher_interval` seconds:
3. Obtain resource (table) lists of the specified prefix (keys of connection_info) from triglav.
4. Connect to hdfs with an appropriate connection info for a resource uri, and find tables which are newer than last check.
5. Store checking information into the status storage file for the next time check.

## Development

### Prepare

```
bundle
bundle exec jbundle install
```

```
./prepare.sh
```

Edit .env file.

### Start

Start up triglav api on localhost.

Run triglav-agent-hdfs as:

```
bundle exec triglav-agent-hdfs --dotenv -c config.yml --debug
```

The debug mode with --debug option ignores the `last_modification_time` value in status file.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/triglav-agent-hdfs. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## ToDo

* write tests
* prepare mocks for both triglav and hdfs
