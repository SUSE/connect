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

      def token_auth(token)
        raise CannotBuildTokenAuth, 'token auth requested, but no token provided' unless token
        "Token token=#{token}"
      end

      def basic_auth

        username, password = System.credentials

        if username && password
          basic_encode(username, password)
        else
          raise CannotBuildBasicAuth, 'cannot get proper username and password'
        end

      end

      # TODO find new name because this is specific to cli usage
      def execute!
        login, password = announce_system unless System.registered?
        Zypper.write_base_credentials(login, password)

        service = activate_subscription(Zypper.base_product)
        System.add_service(service)
      end

      def announce_system
        response = @api.announce_system(token_auth)
        return response.body['login'], response.body['password']
      end

      def activate_subscription(product)
        response = @api.activate_subscription(basic_auth, product)
        Service.new(response.body['sources'], response.body['enabled'], response.body['norefresh'])
      end

      # @param product [Hash] product to query extensions for
      def products_for(product)
        response = @api.addons(basic_auth, product)
        extensions = response.each do |extension|
          Extension.new(extension['name'], '', '', extension['zypper_name'])
        end
        extensions
      end

      private

    end
  end
end
