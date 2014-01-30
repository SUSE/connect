module SUSE
  module Connect
    class Client

      DEFAULT_PORT = '443'
      DEFAULT_HOST = 'scc.suse.com'


      attr_reader :options, :url

      def initialize(opts)

        @options            = {}
        @options[:insecure] = !!opts[:insecure]

        setup_host_and_port(opts)
        construct_url
      end

      def execute!
        announce_system unless System.registered?
        activate_subscription
      end

      def announce_system

      end

      def activate_subscription

      end

      private

        def setup_host_and_port(opts)
          @options[:port] = opts[:port] || DEFAULT_PORT
          @options[:host] = opts[:host] || DEFAULT_HOST
        end

        def construct_url
          @url = requested_secure? ? "https://#{@options[:host]}" : "http://#{@options[:host]}"
        end

        def requested_secure?
          @options[:port] == '443'
        end
    end
  end
end

