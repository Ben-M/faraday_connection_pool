faraday_gem_location = Gem.loaded_specs['faraday'].gem_dir
integration_location = File.join(faraday_gem_location, 'test', 'adapters', 'integration')
require integration_location
require_relative('../../lib/faraday_connection_pool')
require 'mocha/mini_test'

module Adapters
  class NetHttpPooledTest < Faraday::TestCase

    def adapter() :net_http_pooled end

    behaviors = [:NonParallel]
    behaviors << :Compression if RUBY_VERSION >= '1.9'

    Integration.apply(self, *behaviors) do

      def setup
        FaradayConnectionPool::Adapter::NetHttpPooled.purge_connection_pools
      end


      def test_connection_pool_receives_configuration
        test_size = 10
        test_timeout = 0.5

        FaradayConnectionPool.configure do |config|
          config.size = test_size
          config.timeout = test_timeout
        end

        pool = mock_pool
        ConnectionPool.expects(:new).with(:size => test_size, :timeout => test_timeout).returns(pool)

        create_connection.get '/echo'
      end

      def test_connection_from_pool_used
        connection = mock('connection')
        response = mock('response')
        response.stubs(:code)
        response.stubs(:body)
        response.stubs(:each_header)
        pool = ConnectionPool.new { connection }
        ConnectionPool.stubs(:new).returns(pool)

        connection.expects(:get).returns(response)

        create_connection.get '/echo'
      end

      def test_connection_pools_reused
        pool = mock_pool
        ConnectionPool.expects(:new).once.returns(pool)

        create_connection.get '/echo'
        create_connection.get '/echo'
      end

      def test_one_pool_per_host
        pool = mock_pool
        ConnectionPool.expects(:new).twice.returns(pool)
        conn = create_connection
        conn.host = 'hello'
        conn.get '/echo'

        conn.host = 'world'
        conn.get '/echo'
      end

      def test_one_pool_per_port
        pool = mock_pool
        ConnectionPool.expects(:new).twice.returns(pool)
        conn = create_connection
        conn.port = 1
        conn.get '/echo'

        conn.port = 2
        conn.get '/echo'
      end

      def test_keep_alive_header_set
        pool = mock_pool
        ConnectionPool.stubs(:new).returns(pool)

        response = create_connection.get('echo_header', :name => 'connection')

        assert_equal('Keep-Alive', response.body)
      end

      def test_keep_alive_header_not_overwritten
        pool = mock_pool
        ConnectionPool.stubs(:new).returns(pool)

        response = create_connection.get('echo_header', :name => 'connection') do |request|
          request.headers['Connection'] = 'close'
        end

        assert_equal('close', response.body)
      end

      private
      def mock_pool
        connection = Net::HTTP.new(self.class.live_server.host, self.class.live_server.port)
        pool = ConnectionPool.new { connection }
      end
    end
  end
end