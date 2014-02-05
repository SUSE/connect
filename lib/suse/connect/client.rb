require 'base64'

module SUSE
  module Connect
    # Client to interact with API
    class Client

      DEFAULT_PORT = '443'
      DEFAULT_HOST = 'scc.suse.com'

      attr_reader :options, :url, :api

      def initialize(opts)

        @options            = {}
        @options[:token]    = opts[:token]
        @options[:insecure] = !!opts[:insecure]
        setup_host_and_port(opts)
        construct_url
        @api                = Api.new(self)
      end

      def execute!
        announce_system unless System.registered?
        activate_subscription
      end

      def announce_system
        response = @api.announce_system(token_auth)
        body = response.body
        Zypper.write_base_credentials(body['login'], body['password'])
      end

      def activate_subscription
        base_product    = Zypper.base_product
        # TODO: handle non 200ish return codes
        response = @api.activate_subscription(basic_auth, base_product).body
        service = Service.new(response)
        System.add_service(service)
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

      def token_auth
        raise CannotBuildTokenAuth, 'token auth requested, but no token provided' unless options[:token]
        "Token token=#{options[:token]}"
      end

      def basic_auth

        username, password = System.credentials

        if username && password
          "Basic #{::Base64.encode64(username + ':' + password)}"
        else
          raise CannotBuildBasicAuth, 'cannot get proper username and password'
        end

      end
    end
  end
end
