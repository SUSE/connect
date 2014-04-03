# YaST class provides methods emulating SCC's API.
class SUSE::Connect::YaST

  class << self

    attr_accessor :options

    # Announces the system to SCC / the registration server.
    # Usually expects a token / regcode to identify the correct subscription.
    # Writes SCC / system credentials to the system and
    # additionally returns them for convenience.
    #
    # @param params [Hash] optional parameters:
    #  - token [String]
    #  - hostname [String]
    #  - email [String]
    #  - parent [String]
    #  - hwinfo [Hash]
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
    # Returns a service for the activated product
    #
    # @param params [Hash] optional parameters:
    #  - token [String]
    #  - product_ident [String]
    #  - product_version [String]
    #  - arch [String]
    #  - email [String]
    def activate_product(params = {})
      Client.new(params).activate_product(params[:product_ident])
    end

  end

end
