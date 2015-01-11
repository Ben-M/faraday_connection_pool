# FaradayConnectionPool

FaradayConnectionPool provides a persistent Net::HTTP Faraday adapter.
Unlike Net::Persistent, connections are pooled across threads and fibres so that they can be reused more frequently.

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
  config.timeout = 0.5 #If no connection is available from the pool within :timeout seconds the adapter will raise a Timeout::Error.
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
                       exceptions: [CustomException, 'Timeout::Error']
    conn.adapter :net_http_pooled
end
```

## Warning - Proxy Support

The `:net_http_pooled adapter` will not complain if you configure it to use a proxy server, but this code is entirely
untested. Use this at your own risk and file an issue to tell us how it goes.

## Contributing

1. Fork it ( `http://github.com/Ben-M/faraday_connection_pool/fork` )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write your tests and code. Run `script/test` to check that the tests are passing.
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Todo
* [ ] Allow host/port specific configuration
* [ ] Test proxy support