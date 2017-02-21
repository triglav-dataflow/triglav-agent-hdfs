# Triglav::Agent::Hdfs

Triglav Agent for Hdfs

## Requirements

* JRuby >= 9.1.5.0
* Java >= 1.8.0_45


## Prerequisites

* HDFS path to be monitored must be created or modified atomically. To modify HDFS path atomically, use either of following strategies for example:
  * Create a tmp directory and copy files into the directory, then move to the target path
  * Create a marker file such as `_SUCCESS` after copying is done, and monitor the `_SUCESSES` file

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
TRIGLAV_ENV=development bundle exec triglav-agent-hdfs --dotenv -c config.yml
```

## Configuration

Prepare config.yml as [example/config.yml](./example/config.yml).

You can use erb template. You may load environment variables from .env file with `--dotenv` option.

### serverengine section

You can specify any [serverengine](https://github.com/fluent/serverengine) options at this section

### triglav section

Specify triglav api url, and a credential to authenticate.

The access token obtained is stored into a token storage file (--token option).

### hdfs section

This section is the special section for triglav-agent-hdfs.

* **monitor_interval**: The interval to watch tables (number, default: 60)
* **connection_info**: key-value pairs of hdfs connection info where keys are resource URI pattern in regular expression, and values are connection information

## How it behaves

1. Authenticate with triglav
  * Store the access token into the token storage file
  * Read the token from the token storage file next time
  * Refresh the access token if it is expired
2. Repeat followings in `monitor_interval` seconds:
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

Edit `.env` file or `config.yml` file directly.

### Start

Start up triglav api on localhost.

Run triglav-agent-hdfs as:

```
TRIGLAV_ENV=development bundle exec triglav-agent-hdfs --dotenv --debug -c example/config.yml
```

The debug mode with --debug option ignores the `last_modification_time` value in status file.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/triglav-agent-hdfs. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## ToDo

* prepare mocks of both triglav and hdfs for tests
