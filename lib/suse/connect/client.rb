require 'net/http'
require 'suse/toolkit/utilities'

module SUSE
  module Connect
    # Client to interact with API
    class Client

      DEFAULT_URL = 'https://scc.suse.com'
      include SUSE::Toolkit::Utilities

      attr_reader :options, :url, :api

      def initialize(opts)
        @options            = {}
        @options[:token]    = opts[:token]
        @options[:insecure] = !!opts[:insecure]
        @options[:debug]    = !!opts[:verbose]
        @url                = opts[:url] || DEFAULT_URL
        @api                = Api.new(self)
      end

      def register!
        announce_system unless System.registered?
        activate_subscription Zypper.base_product
      end

      def announce_system
        result = @api.announce_system(token_auth(@options[:token])).body
        Zypper.write_base_credentials(result['login'], result['password'])
      end

      def activate_subscription(product_ident)
        result = @api.activate_subscription(basic_auth, product_ident).body
        System.add_service(
          Service.new(result['sources'], result['enabled'], result['norefresh'])
        )
      end

      # @param product [Hash] product to query extensions for
      def products_for(product)
        response = @api.addons(basic_auth, product).body
        response.map do |extension|
          SUSE::Connect::YaST::Extension.new(extension['name'], '', '', extension['zypper_name'])
        end
      end

    end
  end
end
