require 'monitor'
require 'connection_pool'

module FaradayConnectionPool

  class Configuration
    attr_writer :size
    attr_writer :pool_timeout
    attr_writer :keep_alive_timeout

    def size
      @size ||= 5
    end

    def pool_timeout
      @pool_timeout ||= 5
    end

    def keep_alive_timeout
      @keep_alive_timeout ||= 30
    end

  end

  def self.configure
    yield configuration if block_given?
  end

  def self.configuration
    @configuration ||= FaradayConnectionPool::Configuration.new
  end

  class Adapter
    class NetHttpPooled < Faraday::Adapter::NetHttp
      extend MonitorMixin
      @@connection_pools = {}

      def call(env)
        env[:request_headers] ||= {}
        env[:request_headers]['Connection'] = 'Keep-Alive' unless env[:request_headers]['Connection']
        super
      end

      def with_net_http_connection(env)
        connection_pool_for(env).with do |connection|
          yield connection
         end
      end

      def self.purge_connection_pools
        synchronize do
          @@connection_pools = {}
        end
      end

      private
      def connection_pool_for(env)
        self.class.synchronize do
          connection_with_keep_alive_time = -> do
            connection = net_http_connection(env)
            connection.keep_alive_timeout = FaradayConnectionPool.configuration.keep_alive_timeout
            connection
          end

          @@connection_pools[pool_key(env)] ||=
            ConnectionPool.new(:size => FaradayConnectionPool.configuration.size,
                               :timeout => FaradayConnectionPool.configuration.pool_timeout,
                               &connection_with_keep_alive_time)
        end
      end

      def pool_key(env)
        "#{env[:url].host}:#{env[:url].port}:#{proxy_identifier(env)}"
      end

      def proxy_identifier(env)
        env[:request][:proxy] ? "#{env[:request][:proxy][:uri]}" : ""
      end

    end
  end
end

Faraday::Adapter.register_middleware :net_http_pooled => FaradayConnectionPool::Adapter::NetHttpPooled