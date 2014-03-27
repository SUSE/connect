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
        response = @api.announce_system(Utilities.token_auth(@options[:token]))
        body = response.body
        Zypper.write_base_credentials(body['login'], body['password'])
      end

      def activate_subscription
        base_product    = Zypper.base_product
        response = @api.activate_subscription(Utilities.basic_auth, base_product)
        service = Service.new(response.body['sources'], response.body['enabled'], response.body['norefresh'])
        System.add_service(service)
      end

      private

    end
  end
end
