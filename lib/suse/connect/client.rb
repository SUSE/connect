require 'net/http'
require 'suse/toolkit/utilities'

module SUSE
  module Connect
    # Client to interact with API
    class Client

      include SUSE::Toolkit::Utilities

      DEFAULT_URL = 'https://scc.suse.com'

      attr_reader :options, :url, :api

      def initialize(opts)
        @options            = opts
        @url                = opts[:url] || DEFAULT_URL
        # !!: Set :insecure and :debug explicitly to boolean values.
        @options[:insecure] = !!opts[:insecure]
        @options[:debug]    = !!opts[:verbose]
        @options[:token]    = opts[:token]
        @api                = Api.new(self)
      end

      def register!
        unless System.registered?
          login, password = announce_system

          credentials = Credentials.new(login, password, Credentials::GLOBAL_CREDENTIALS_FILE)
          credentials.write
        end

        service = activate_product(Zypper.base_product)
        System.add_service(service)
      end

      # Announce system via SCC/Registration Proxy
      #
      # @returns: [Array] login, password tuple. Those credentials are given by SCC/Registration Proxy
      def announce_system
        response = @api.announce_system(token_auth(@options[:token]))
        [response.body['login'], response.body['password']]
      end

      def activate_product(product_ident)
        result = @api.activate_product(basic_auth, product_ident).body
        Service.new(result['sources'], result['enabled'], result['norefresh'])
      end

      # @param product [Hash] product to query extensions for
      def list_products(product_ident)
        result = @api.addons(basic_auth, product_ident).body
        result.map do |product|
          SUSE::Connect::Product.new(product['name'], '', '', product['zypper_name'])
        end
      end

      # @returns: Empty body and 204 status code
      def deregister!
        @api.deregister(basic_auth)
        System.remove_credentials
      end
    end
  end
end
