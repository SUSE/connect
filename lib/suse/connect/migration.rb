require 'suse/connect/core_ext/hash_refinement'

module SUSE
  module Connect
    # Migration class is an abstraction layer for SLE migration script
    # Migration script call this class from: https://github.com/nadvornik/zypper-migration/blob/master/zypper-migration
    class Migration
      using SUSE::Connect::CoreExt::HashRefinement

      class << self
        # Returns installed and activated products on the system
        # @param [Hash] client_params parameters to instantiate {Client}
        # @return [Array <OpenStruct>] the list of system products
        def system_products(client_params = {})
          config = SUSE::Connect::Config.new.merge!(client_params)
          Status.new(config).system_products.map(&:to_openstruct)
        end

        # Restores a state of the system before migration
        def rollback(client_params = {})
          log.info('Starting to sync system product activations to the server. This can take some time...')
          config = SUSE::Connect::Config.new.merge!(client_params)
          client = Client.new(config)
          status = Status.new(config)
          base_product = Zypper.base_product

          # First rollback the base_product
          service = client.downgrade_product(base_product)
          refresh_service service

          # Fetch the product tree and get all installed products in right order
          installed = Hash[status.installed_products.collect { |p| [p.identifier, p] }]
          tree = client.show_product(base_product)

          extensions = client.flatten_tree(tree).select do |extension|
            installed.key? extension.identifier
          end.map(&:identifier)

          # Rollback all extensions
          extensions.each do |extension|
            service = client.downgrade_product(installed[extension])
            refresh_service service
          end

          # Synchronize installed products with SCC activations (removes obsolete activations)
          client.synchronize(status.installed_products)

          # Set releasever to the new baseproduct version
          target_version = base_product.version.to_s
          SUSE::Connect::Zypper.set_release_version(target_version)
        end

        # Forwards the repository which should be enabled with zypper
        # @param [String] repository name to enable
        def enable_repository(name)
          SUSE::Connect::Zypper.enable_repository(name)
        end

        # Forwards the repository which should be disabled with zypper
        # @param [String] repository name to disable
        def disable_repository(name)
          SUSE::Connect::Zypper.disable_repository(name)
        end

        # Returns the list of available repositories
        # @return [Array <OpenStruct>] the list of zypper repositories
        def repositories
          # INFO: use block instead of .map(&:to_openstruct) see https://bugs.ruby-lang.org/issues/9786
          # rubocop:disable SymbolProc
          SUSE::Connect::Zypper.repositories.map { |r| r.to_openstruct }
        end

        # Forwards the service which should be added with zypper
        # @param [String] service_url the url from the service to add
        # @param [String] service_name the name of the service to add
        def add_service(service_url, service_name)
          SUSE::Connect::Zypper.add_service(service_url, service_name)
        end

        # Forwards the service names which should be removed with zypper
        # @param [String] service_name the name of the service to remove
        def remove_service(service_name)
          SUSE::Connect::Zypper.remove_service(service_name)
        end

        # Finds the solvable products available on the system
        # @param [String] identifier e.g. SLES
        # @return [Array <OpenStruct>] the list of solvable products available on the system
        def find_products(identifier)
          # INFO: use block instead of .map(&:to_openstruct) see https://bugs.ruby-lang.org/issues/9786
          # rubocop:disable SymbolProc
          SUSE::Connect::Zypper.find_products(identifier).map { |p| p.to_openstruct }
        end

        # Installs the product release package
        # @param [String] identifier e.g. SLES
        def install_release_package(identifier)
          SUSE::Connect::Zypper.install_release_package(identifier)
        end

        # Removes service and readds service with current url and name
        # @param Service service which should be refreshed
        def refresh_service(service)
          # INFO: Remove old and new service because this could be called after filesystem rollback or
          # from inside a failed migration
          remove_service service.name
          remove_service service.obsoleted_service_name

          # INFO: Add new service for the same product but with new/valid service url
          add_service service.url, service.name
        end
      end
    end
  end
end
