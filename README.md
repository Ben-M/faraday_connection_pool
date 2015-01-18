# FaradayConnectionPool

FaradayConnectionPool provides a persistent Net::HTTP Faraday adapter.
Unlike Net::HTTP::Persistent, which has a connection-per-thread, connections are pooled across all threads and you will always get the most recently used connection. This should mean that you are more likely to get an existing connection with a reduced chance of getting a connection reset
## Installation

Add this line to your application's Gemfile:

    gem 'faraday_connection_pool'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install faraday_connection_pool


## Usage

1. If necessary `require 'faraday_connection_pool'`

2. Configure FaradayConnectionPool:

```ruby
FaradayConnectionPool.configure do |config|
  config.size = 5 #The number of connections to held in the pool. There is a separate pool for each host/port.
  config.pool_timeout = 5 #If no connection is available from the pool within :pool_timeout seconds the adapter will raise a Timeout::Error.
  config.keep_alive_timeout = 30  #Connections which has been unused for :keep_alive_timeout seconds are not reused.
end
```

3. Configure your Faraday connections to use the `:net_http_pooled` adapter provided by the gem:

```ruby
Faraday.new(:url => 'http://klarna.com') do |conn|
  conn.adapter :net_http_pooled
end
```

## Warning - Retries

FaradayConnectionPool will not automatically try and repair broken connections, so you should configure Faraday to retry
for you:

```ruby
Faraday.new do |conn|
  conn.request :retry, max: 2, interval: 0.05,
                       interval_randomness: 0.5, backoff_factor: 2
                       exceptions: [ Faraday::Error::ConnectionFailed ]
    conn.adapter :net_http_pooled
end
```

## Warning - Proxy Support

The `:net_http_pooled adapter` will not complain if you configure it to use a proxy server, but this code is entirely
untested. Use this at your own risk and file an issue to tell us how it goes.

## Tests

Run tests with `script/test`.
The test framework pulls in files from Faraday to save us setting up an integration test framework here.

## Contributing

1. Fork it ( `http://github.com/Ben-M/faraday_connection_pool/fork` )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write your tests and code. Run `script/test` to check that the tests are passing.
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Todo
* [ ] Make Faraday::Error::ConnectionFailed less general, so we can retry only Errno::ECONNRESET
* [ ] Allow host/port specific configuration
* [ ] Test proxy support
