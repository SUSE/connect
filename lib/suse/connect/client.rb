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

      # rubocop:disable CyclomaticComplexity
      def initialize(opts = {})
        @config = Config.new

        @options              = opts
        @url = @options[:url] = opts[:url] || @config.url || DEFAULT_URL
        @options[:insecure]   = !!opts[:insecure] || @config.insecure
        @options[:debug]      = !!opts[:debug]
        @options[:language]   = opts[:language] || @config.language
        @options[:token]      = opts[:token] || @config.regcode
        @options[:product]    = opts[:product]
        @api                  = Api.new(self)

        # Update config attributes
        @config.merge!(@options)

        write_config if opts[:write_config]
        log.debug "Merged options: #{@options}"
      end

      # Announces the system, activates the product on SCC and adds the service to the system
      def register!
        announce_or_update
        product = @options[:product] || Zypper.base_product
        service = activate_product(product, @options[:email])
        System.add_service(service)
        print_success_message product
      end

      # @returns: Empty body and 204 status code
      def deregister!
        @api.deregister(system_auth)
        System.remove_credentials
      end

      # Announce system via SCC/Registration Proxy
      #
      # @returns: [Array] login, password tuple. Those credentials are given by SCC/Registration Proxy
      def announce_system(distro_target = nil, instance_data_file = nil)
        instance_data = System.read_file(instance_data_file) if instance_data_file
        response = @api.announce_system(token_auth(@options[:token]), distro_target, instance_data)
        [response.body['login'], response.body['password']]
      end

      # Re-send the system's hardware details on SCC
      #
      def update_system(distro_target = nil, instance_data_file = nil)
        instance_data = System.read_file(instance_data_file) if instance_data_file
        @api.update_system(system_auth, distro_target, instance_data)
      end

      # Activate a product
      #
      # @param product [SUSE::Connect::Zypper::Product]
      # @returns: Service for this product
      def activate_product(product, email = nil)
        result = @api.activate_product(system_auth, product, email).body
        Remote::Service.new(result)
      end

      # Upgrade a product
      # System upgrade (eg SLES11 -> SLES12) without regcode
      #
      # @param product [Remote::Product] desired product to be upgraded
      # @returns: Service for this product
      def upgrade_product(product)
        result = @api.upgrade_product(system_auth, product).body
        Remote::Service.new(result)
      end

      # @param product [Remote::Product] product to query extensions for
      def show_product(product)
        result = @api.show_product(system_auth, product).body
        Remote::Product.new(result)
      end

      # writes the config file to disk with the currently active config options
      def write_config
        @config.write
      end

      # @returns: body described in https://github.com/SUSE/connect/wiki/SCC-API-(Implemented)#response-12 and
      # 200 status code
      def system_services
        @api.system_services(system_auth)
      end

      # @returns: body described in https://github.com/SUSE/connect/wiki/SCC-API-(Implemented)#response-13 and
      # 200 status code
      def system_subscriptions
        @api.system_subscriptions(system_auth)
      end

      # @returns: body described in https://github.com/SUSE/connect/wiki/SCC-API-(Implemented)#response-14 and
      # 200 status code
      def system_activations
        @api.system_activations(system_auth)
      end

      private

      # Announces the system to the server, receiving and storing its credentials.
      # When already announced, sends the current hardware details to the server
      def announce_or_update
        if System.credentials?
          update_system
        else
          login, password = announce_system(nil, @options[:instance_data_file])
          Credentials.new(login, password, Credentials.system_credentials_file).write
        end
      end

      def print_success_message(product)
        log.info "Registered #{product.identifier} #{product.version} #{product.arch}"
        log.info "Rooted at: #{@options[:filesystem_root]}" if @options[:filesystem_root]
        log.info "To server: #{@options[:url]}" if @options[:url]
        log.info "Using E-Mail: #{@options[:email]}" if @options[:email]
      end

    end

  end

end
