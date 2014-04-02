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

      # TODO: find new name because this is specific to cli usage
      def execute!

        unless System.registered?
          login, password = announce_system
          Zypper.write_base_credentials(login, password)
        end

        service = activate_subscription(Zypper.base_product)
        System.add_service(service)
      end

      # Announce system via SCC/Registration Proxy
      #
      # @returns: [Array] login, password tuple. Those credentials are given by SCC/Registration Proxy
      def announce_system
        response = @api.announce_system(token_auth(@options[:token]))
        [response.body['login'], response.body['password']]
      end

      def activate_subscription(product)
        response = @api.activate_subscription(basic_auth, product)
        Service.new(response.body['sources'], response.body['enabled'], response.body['norefresh'])
      end

      # @param product [Hash] product to query extensions for
      def products_for(product)
        response = @api.addons(basic_auth, product).body
        response.map do |extension|
          Yast::Extension.new(extension['name'], '', '', extension['zypper_name'])
        end
      end

    end
  end
end
