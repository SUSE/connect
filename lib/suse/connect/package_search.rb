module SUSE
  module Connect
    # Enable connect and zypper extensions/scripts to search packages for a
    # certain product
    class PackageSearch
      class << self
        # Search packages depending on the product and its extension/module
        # tree.
        #
        # @param query [String] package to search
        # @param product [SUSE::Connect::Zypper::Product] product to base search on
        # @param config_params [<Hash>] overwrites from the config file
        #
        # @return [Array< <Hash>>] Returns all matched packages or an empty array if no matches where found
        def search(query, product: Zypper.base_product, config_params: {})
          config = SUSE::Connect::Config.new.merge!(config_params)
          api = SUSE::Connect::Api.new(config)

          api.package_search(product, query).body['data']
        end
      end
    end
  end
end
