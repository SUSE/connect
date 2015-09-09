require 'net/http'
require 'suse/toolkit/utilities'

module SUSE
  module Connect
    # Client to interact with API
    class Client
      include SUSE::Toolkit::Utilities
      include Logger

      attr_reader :config, :api

      # builds an instance of the client
      #
      # @param client [Config] populated config merged with overwrites on top of those being read from config file
      #
      # @return [Client]
      def initialize(config)
        @config = config
        @api    = Api.new(self)
        log.debug "Merged options: #{@config}"
      end

      # Announces the system, activates the product on SCC and adds the service to the system
      def register!
        announce_or_update
        product = @config.product || Zypper.base_product
        service = activate_product(product, @config.email)
        Zypper.install_release_package(product.identifier) if @config.product
        System.add_service(service)
        print_success_message product
      end

      # @returns: Empty body and 204 status code
      def deregister!
        @api.deregister(system_auth)
        System.cleanup!
      end

      # Announce system via SCC/Registration Proxy
      #
      # @returns: [Array] login, password tuple. Those credentials are given by SCC/Registration Proxy
      def announce_system(distro_target = nil, instance_data_file = nil)
        instance_data = System.read_file(instance_data_file) if instance_data_file
        params = [token_auth(@config.token), distro_target, instance_data]
        params.push(@config.namespace) if @config.namespace

        response = @api.announce_system(*params)
        [response.body['login'], response.body['password']]
      end

      # Re-send the system's hardware details on SCC
      #
      def update_system(distro_target = nil, instance_data_file = nil)
        instance_data = System.read_file(instance_data_file) if instance_data_file
        params = [system_auth, distro_target, instance_data]
        params.push(@config.namespace) if @config.namespace

        @api.update_system(*params)
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

      # Downgrade a product
      # System downgrade (eg SLES12 SP1 -> SLES12) without regcode
      #
      # @param product [Remote::Product] desired product to be upgraded
      # @returns: Service for this product
      alias_method :downgrade_product, :upgrade_product

      # Synchronize system products with registration server
      #
      # @param products [Array] List of activated system products to synchronize
      def synchronize(products)
        @api.synchronize(system_auth, products).body
      end

      # @param product [Remote::Product] product to query extensions for
      def show_product(product)
        result = @api.show_product(system_auth, product).body
        Remote::Product.new(result)
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

      # Lists all available upgrade paths for a given list of products
      #
      # @param [Array <Remote::Product>] the list of currently installed products in the system
      #
      # @return [Array <Array <Remote::Product>>] the list of possible upgrade paths for the given products,
      #   where an upgrade path is an array of Remote::Product objects.
      def system_migrations(products)
        upgrade_paths = @api.system_migrations(system_auth, products).body
        upgrade_paths.map do |upgrade_path|
          upgrade_path.map do |product_attributes|
            Remote::Product.new(product_attributes)
          end
        end
      end

      private

      # Announces the system to the server, receiving and storing its credentials.
      # When already announced, sends the current hardware details to the server
      def announce_or_update
        if System.credentials?
          update_system
        else
          login, password = announce_system(nil, @config.instance_data_file)
          Credentials.new(login, password, Credentials.system_credentials_file).write
        end
      end

      def print_success_message(product)
        log.info "Registered #{product.identifier} #{product.version} #{product.arch}"
        log.info "Rooted at: #{@config.filesystem_root}" if @config.filesystem_root
        log.info "To server: #{@config.url}" if @config.url
        log.info "Using E-Mail: #{@config.email}" if @config.email
      end
    end
  end
end
