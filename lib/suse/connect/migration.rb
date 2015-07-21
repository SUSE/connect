module SUSE
  module Connect

    # Migration class is an abstraction layer for SLE migration script
    # Migration script call this class from: https://github.com/nadvornik/zypper-migration/blob/master/zypper-migration
    class Migration
      class << self
        # Returns installed and activated products on the system
        # @param [Hash] client_params parameters to instantiate {Client}
        # @return [Array <OpenStruct>] the list of system products
        def system_products(client_params = {})
          config = SUSE::Connect::Config.new.merge!(client_params)
          Status.new(config).system_products.map(&:to_openstruct)
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

      end
    end

  end
end
