faraday_gem_location = Gem.loaded_specs['faraday'].gem_dir
integration_location = File.join(faraday_gem_location, 'test', 'adapters', 'integration')
require integration_location
require 'minitest/rspec_mocks'
require_relative('../../lib/faraday_connection_pool')

module Adapters
  class NetHttpPooledTest < Faraday::TestCase
    include MiniTest::RSpecMocks

    def adapter() :net_http_pooled end

    behaviors = [:NonParallel]
    behaviors << :Compression if RUBY_VERSION >= '1.9'

    Integration.apply(self, *behaviors) do

      def setup
        FaradayConnectionPool::Adapter::NetHttpPooled.purge_connection_pools
      end

      def test_connection_pool_receives_size_and_pool_timeout
        test_size = 10
        test_pool_timeout = 0.5

        FaradayConnectionPool.configure do |config|
          config.size = test_size
          config.pool_timeout = test_pool_timeout
        end

        expect(ConnectionPool).to receive(:new).with(:size => test_size, :timeout => test_pool_timeout).and_call_original

        create_connection.get '/echo'
      end

      def test_connection_created_with_keep_alive_timeout
        test_keep_alive_timeout = 18
        FaradayConnectionPool.configure do |config|
          config.keep_alive_timeout = test_keep_alive_timeout
        end

        expect_any_instance_of(Net::HTTP).to receive(:keep_alive_timeout=).with(test_keep_alive_timeout)
        create_connection.get '/echo'
      end

      def test_connection_from_pool_used
        connection = double('connection')
        pool = ConnectionPool.new { connection }
        allow(ConnectionPool).to receive(:new).and_return(pool)
        response = double('response', :code => 200, :body => :ok, :each_header => true)

        expect(connection).to receive(:get).and_return(response)

        assert_equal :ok, create_connection.get('/echo').body
      end

      def test_connection_pools_reused
        expect(ConnectionPool).to receive(:new).once.and_call_original

        create_connection.get '/echo'
        create_connection.get '/echo'
      end

      def test_one_pool_per_host
        expect(ConnectionPool).to receive(:new).twice.and_return(test_pool)

        conn = create_connection
        conn.host = 'hello'
        conn.get '/echo'

        conn.host = 'world'
        conn.get '/echo'
      end

      def test_one_pool_per_port
        expect(ConnectionPool).to receive(:new).twice.and_return(test_pool)

        conn = create_connection
        conn.port = 1
        conn.get '/echo'

        conn.port = 2
        conn.get '/echo'
      end

      def test_keep_alive_header_set
        response = create_connection.get('echo_header', :name => 'connection')

        assert_equal('Keep-Alive', response.body)
      end

      def test_keep_alive_header_not_overwritten
        response = create_connection.get('echo_header', :name => 'connection') do |request|
          request.headers['Connection'] = 'close'
        end

        assert_equal('close', response.body)
      end

      private
      def test_pool
        connection = Net::HTTP.new(self.class.live_server.host, self.class.live_server.port)
        pool = ConnectionPool.new { connection }
      end
    end
  end
end