# YaST class provides methods emulating SCC's API.
class SUSE::Connect::YaST

  class << self

    # Announces the system to SCC / the registration server.
    # Usually expects a token / regcode to identify the correct subscription.
    # Additionally, distro_target should be set to avoid calls to Zypper.
    # Gets system credentials from SCC.
    # Additionally, returns the credentials for convenience.
    #
    # @param [Hash] params
    #   * :token [String] registration code/token
    #   * :hostname [String]
    #   * :distro_target [String]
    #   * :parent [String]
    #   * :hwinfo [Hash]
    #
    # @return [Array <String>] SCC / system credentials - login and password tuple
    def announce_system(params = {})
      Client.new(params).announce_system(params[:distro_target])
    end

    # Activates a product on SCC / the registration server.
    # Expects a product_ident to identify the correct service.
    # Mostly requires token / regcode (except for free extensions or upgrades).
    # Gets a service for the product from SCC.
    # Additionally, returns the service for convenience.
    #
    # @param [Hash] params
    #  - :token [String]
    #  - :product_ident [String]
    #  - :product_version [String]
    #  - :arch [String]
    #  - :email [String]
    #
    # @return [Service] Service
    def activate_product(params = {})
      Client.new(params).activate_product(params[:product_ident], params[:email])
    end

    # Lists all available products for a system.
    # Accepts a parameter product_ident, which scopes the result set down to all
    # products for the system that are extensions to the specified product.
    # Gets the list from SCC and returns them.
    #
    # @param [Hash] params
    #  * :product_ident [String]
    #
    # @return [Array <Product>] array of {Product}s
    def list_products(params = {})
      Client.new(params).list_products(params[:product_ident])
    end

  end

end
