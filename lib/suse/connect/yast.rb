# YaST class provides methods emulating SCC's API.
class SUSE::Connect::YaST

  class << self

    attr_accessor :options

    # Announces the system to SCC / the registration server.
    # Usually expects a token / regcode to identify the correct subscription.
    # Gets system credentials from SCC and writes them to the system.
    # Additionally, returns the credentials for convenience.
    #
    # @param params [Hash] optional parameters:
    #  - token [String]
    #  - hostname [String]
    #  - email [String]
    #  - parent [String]
    #  - hwinfo [Hash]
    #
    # == Returns:
    # SCC / system credentials [Hash]:
    #  - login [String]
    #  - password [String]
    def announce_system(params = {})
      Client.new(params).announce_system
    end

    # Activates a product on SCC / the registration server.
    # Expects a product_ident to identify the correct service.
    # Mostly requires token / regcode (except for free extensions or upgrades).
    # Gets a service for the product from SCC and adds it to the system.
    # Additionally, returns the service for convenience.
    #
    # @param params [Hash] optional parameters:
    #  - token [String]
    #  - product_ident [String]
    #  - product_version [String]
    #  - arch [String]
    #  - email [String]
    #
    # == Returns:
    # Service [Service]
    def activate_product(params = {})
      Client.new(params).activate_product(params[:product_ident])
    end

    # Lists all available products for a system.
    # Accepts a parameter product_ident, which scopes the result set down to all
    # products for the system that are extensions to the specified product.
    # Gets the list from SCC and returns them.
    #
    # @param params [Hash] optional parameters:
    #  - product_ident [String]
    #
    # == Returns:
    # [Product, Product] [Array]
    def list_products(params = {})
      Client.new(params).list_products(params[:product_ident])
    end

  end

end
