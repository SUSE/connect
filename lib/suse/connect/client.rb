require 'net/http'
require 'suse/toolkit/utilities'

module SUSE
  module Connect
    # Client to interact with API
    class Client

      include SUSE::Toolkit::Utilities
      include Logger

      DEFAULT_URL = 'https://scc.suse.com'

      attr_reader :options, :url, :api

      def initialize(opts)
        # Read SUSConnect.yml config file
        config = Config.new

        @options            = opts
        @url                = opts[:url] || config.url || DEFAULT_URL
        @options[:insecure] = config.insecure
        # !!: Set :debug explicitly to boolean values.
        @options[:debug]    = !!opts[:verbose]
        @options[:language] = opts[:language] || config.language
        @options[:token]    = opts[:token] || config.regcode
        @options[:product]  = opts[:product]
        @api                = Api.new(self)
        log.debug "Merged options: #{@options}"
      end

      # Activates a product and writes credentials file if the system was not yet announced
      def register!
        announce_if_not_yet
        product = @options[:product] || Zypper.base_product
        service = activate_product(product)
        System.add_service(service)
      end

      # @returns: Empty body and 204 status code
      def deregister!
        @api.deregister(basic_auth)
        System.remove_credentials
      end

      # Announce system via SCC/Registration Proxy
      #
      # @returns: [Array] login, password tuple. Those credentials are given by SCC/Registration Proxy
      def announce_system(distro_target = nil)
        response = @api.announce_system(token_auth(@options[:token]), distro_target)
        [response.body['login'], response.body['password']]
      end

      # Activate a product
      #
      # @param product_ident [Hash] with product parameters
      # @returns: Service for this product
      def activate_product(product_ident, email = nil)
        result = @api.activate_product(basic_auth, product_ident, email).body
        Service.new(result['sources'], result['enabled'], result['norefresh'])
      end

      # Upgrade a product
      # System upgrade (eg SLES11 -> SLES12) without regcode
      #
      # @param product_ident [Hash] with product parameters
      # @returns: Service for this product
      def upgrade_product(product_ident)
        result = @api.upgrade_product(basic_auth, product_ident).body
        Service.new(result['sources'], result['enabled'], result['norefresh'])
      end

      # @param product_ident [Hash] product to query extensions for
      def list_products(product_ident)
        result = @api.addons(basic_auth, product_ident).body
        result.map do |product|
          SUSE::Connect::Product.new(product)
        end
      end

      # @returns: body described in https://github.com/SUSE/connect/wiki/SCC-API-(Implemented)#response-12 and
      # 200 status code
      def system_services
        @api.system_services(basic_auth)
      end

      # @returns: body described in https://github.com/SUSE/connect/wiki/SCC-API-(Implemented)#response-13 and
      # 200 status code
      def system_subscriptions
        @api.system_subscriptions(basic_auth)
      end

      # @returns: print to $stdout status of current subscriptions
      # 200 status code
      def status
        Status.new(self)
      end

      private

      def announce_if_not_yet
        unless System.registered?
          login, password = announce_system
          Credentials.new(login, password, Credentials.system_credentials_file).write
        end
      end

    end

  end

end
