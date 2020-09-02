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
        @api    = Api.new(@config)
        log.debug "Merged options: #{@config}"
      end

      # Announces the system, activates the product on SCC and adds the service to the system
      def register!
        print_information(:register)
        announce_or_update
        product = @config.product || Zypper.base_product

        register_product(product, @config.product ? true : false)

        # Only register recommended packages for base products
        register_product_tree(show_product(product)) if product.isbase

        log.info "\nSuccessfully registered system\n".log_green.bold
      end

      # Activate the product, add the service and install the release package
      def register_product(product, install_release_package = true)
        log.info "\nActivating #{product.identifier} #{product.version} #{product.arch} ..."
        service = activate_product(product, @config.email)

        log.info '-> Adding service to system ...'
        System.add_service(service, !@config.no_zypper_refs)
        if install_release_package
          log.info '-> Installing release package ...'
          Zypper.install_release_package(product.identifier)
        end
      end

      # Deregisters a whole system or a single product
      #
      # @returns: Empty body and 204 status code
      def deregister!
        if File.exist?('/usr/sbin/registercloudguest')
          raise UnsupportedOperation,
            'De-registration is disabled for on-demand instances. Use `registercloudguest --clean` instead.'
        end
        raise SystemNotRegisteredError unless registered?
        print_information :deregister
        if @config.product
          deregister_product(@config.product)
        else
          # obtain base product service information
          base_product_service = upgrade_product(Zypper.base_product)

          tree = show_product(Zypper.base_product)
          installed = Zypper.installed_products.map(&:identifier)
          dependencies = flatten_tree(tree).select { |e| installed.include? e[:identifier] }

          dependencies.reverse.each do |product|
            deregister_product(product)
          end
          @api.deregister(system_auth)

          remove_or_refresh_service(base_product_service)
          log.info "\nCleaning up ..."
          System.cleanup!
          log.info "Successfully deregistered system\n".log_green.bold
        end
      end

      # Flatten a product tree into an array
      #
      # @param tree Remote::Product
      #
      # @returns an array of the flattend tree
      def flatten_tree(tree)
        result = []
        tree.extensions.each do |extension|
          result.push(extension)
          result += flatten_tree(extension)
        end
        result
      end

      # Announce system via SCC/Registration Proxy
      #
      # @returns: [Array] login, password tuple. Those credentials are given by SCC/Registration Proxy
      def announce_system(distro_target = nil, instance_data_file = nil)
        log.info "\nAnnouncing system to #{@config.url} ...".bold
        instance_data = System.read_file(instance_data_file) if instance_data_file
        params = [token_auth(@config.token), distro_target, instance_data]
        params.push(@config.namespace) if @config.namespace

        response = @api.announce_system(*params)

        [response.body['login'], response.body['password']]
      end

      # Re-send the system's hardware details on SCC
      #
      def update_system(distro_target = nil, instance_data_file = nil)
        log.info "\nUpdating system details on #{@config.url} ...".bold
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

      # Deactivate a product
      #
      # @param product [SUSE::Connect::Remote::Product]
      # @returns: Service for this product
      def deactivate_product(product)
        result = @api.deactivate_product(system_auth, product).body
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

      # @returns: body described in https://github.com/SUSE/connect/blob/master/doc/SCC-API-(Implemented).md#response-15 and
      # 200 status code
      def system_services
        @api.system_services(system_auth)
      end

      # @returns: body described in https://github.com/SUSE/connect/blob/master/doc/SCC-API-(Implemented).md#response-19 and
      # 200 status code
      def system_subscriptions
        @api.system_subscriptions(system_auth)
      end

      # @returns: body described in https://github.com/SUSE/connect/blob/master/doc/SCC-API-(Implemented).md#response-20 and
      # 200 status code
      def system_activations
        @api.system_activations(system_auth)
      end

      # Lists all available upgrade paths for a given list of products
      #
      # @param [Array <Remote::Product>] the list of currently installed products in the system
      # @param kind [Symbol] :online or :offline. Whether to get online or offline migrations.
      # @param target_base_product [Remote::Product] (optional) Filter the resulting migration paths for the given base product.
      #   Only used by the backend when kind is :offline.
      #
      # @return [Array <Array <Remote::Product>>] the list of possible upgrade paths for the given products,
      #   where an upgrade path is an array of Remote::Product objects.
      def system_migrations(products, target_base_product: nil, kind:)
        args = { kind: kind, target_base_product: target_base_product }.reject { |_, v| v.nil? }

        upgrade_paths = @api.system_migrations(system_auth, products, args).body
        upgrade_paths.map do |upgrade_path|
          upgrade_path.map do |product_attributes|
            Remote::Product.new(product_attributes)
          end
        end
      end

      # List available Installer-Updates repositories for the given product
      #
      # @param product [Remote::Product] list repositories for this product
      #
      # @return [Array <Hash>] list of Installer-Updates repositories
      def list_installer_updates(product)
        @api.list_installer_updates(product).body
      end

      private

      # Traverses (depth-first search) the product tree
      # and registers the recommended and available products.
      def register_product_tree(product)
        product.extensions.each do |extension|
          # We need to explicitly check whether `.available` is `false`,
          # because SCC does not return this attribute, only SMT & RMT do.
          if extension.recommended && extension.available != false
            register_product(extension)
            register_product_tree(extension)
          end
        end
      end

      def deregister_product(product)
        raise BaseProductDeactivationError if product == Zypper.base_product
        log.info "\nDeactivating #{product.identifier} #{product.version} #{product.arch} ..."
        service = deactivate_product product
        remove_or_refresh_service(service)
        log.info '-> Removing release package ...'
        Zypper.remove_release_package product.identifier
      end

      # Announces the system to the server, receiving and storing its credentials.
      # When already announced, sends the current hardware details to the server
      def announce_or_update
        if registered?
          update_system
        else
          distro_target = @config.product ? @config.product.distro_target : nil
          login, password = announce_system(distro_target,
                                            @config.instance_data_file)
          Credentials.new(login, password, Credentials.system_credentials_file).write
        end
      end

      def registered?
        System.credentials?
      end

      # SMT provides one service for all products, removing it would remove all repositories.
      # Refreshing the service instead to remove the repos of deregistered product.
      def remove_or_refresh_service(service)
        if service.name == 'SMT_DUMMY_NOREMOVE_SERVICE'
          log.info '-> Refreshing service ...'
          Zypper.refresh_all_services
        else
          log.info '-> Removing service from system ...'
          System.remove_service service
        end
      end

      def print_information(action)
        server = (@config.url == 'https://scc.suse.com') ? 'SUSE Customer Center' : "registration proxy #{@config.url}"
        if action == :register
          log.info "Registering system to #{server}".bold if @config.url
        elsif @config.url
          log.info "Deregistering system from #{server}".bold
        end
        log.info "Rooted at: #{@config.filesystem_root}" if @config.filesystem_root
        log.info "Using E-Mail: #{@config.email}" if @config.email
      end
    end
  end
end
