require 'net/http'

module SUSE
  module Connect
    # Client to interact with API
    class Client
      # TODO: drop this in favor of clear auth implementation
      include ::Net::HTTPHeader

      DEFAULT_URL = 'https://scc.suse.com'

      attr_reader :options, :url, :api

      def initialize(opts)
        @options            = {}
        @options[:token]    = opts[:token]
        @options[:insecure] = !!opts[:insecure]
        @options[:debug]    = !!opts[:verbose]
        @url                = opts[:url] || DEFAULT_URL
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
        response = @api.activate_subscription(basic_auth, base_product)

        service = Service.new(response.body['sources'], response.body['enabled'], response.body['norefresh'])
        System.add_service(service)
      end

      private

      def token_auth
        raise CannotBuildTokenAuth, 'token auth requested, but no token provided' unless options[:token]
        "Token token=#{options[:token]}"
      end

      def basic_auth

        username, password = System.credentials

        if username && password
          basic_encode(username, password)
        else
          raise CannotBuildBasicAuth, 'cannot get proper username and password'
        end

      end
    end
  end
end
