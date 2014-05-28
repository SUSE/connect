module SUSE
  module Connect

    # YaST class provides methods emulating SCC's API.
    # YaST call this class from:
    # https://github.com/yast/yast-registration/blob/master/src/lib/registration/registration.rb
    class YaST
      class << self

        # Announces the system to SCC / the registration server.
        # Expects a token / regcode to identify the correct subscription.
        # Additionally, distro_target should be set to avoid calls to Zypper.
        # Returns the system credentials from SCC.
        #
        # @param [Hash] params
        #   * :token [String] registration code/token
        #   * :distro_target [String]
        #
        # @return [Array <String>] SCC / system credentials - login and password tuple
        def announce_system(params = {})
          Client.new(params).announce_system(params[:distro_target])
        end

        # Activates a product on SCC / the registration server.
        # Expects product_ident parameter to be a hash identifying the product.
        # Requires a token / regcode except for free products/extensions.
        # Returns a service object for the activated product.
        #
        # @param [Hash] params
        #  - :token [String]
        #  - :product_ident [Hash] containing: :name, :version, :arch
        #  - :email [String]
        #
        # @return [Service] Service
        def activate_product(params = {})
          Client.new(params).activate_product(params[:product_ident], params[:email])
        end

        # Upgrades a product on SCC / the registration server.
        # Expects product_ident parameter to be a hash identifying the new product.
        # Token / regcode is not required. The new product needs to be available to the regcode the old
        # product was registered with, or be a free product.
        # Returns a service object for the new activated product.
        #
        # @param [Hash] params
        #  - :product_ident [Hash] containing: :name, :version, :arch
        #
        # @return [Service] Service
        def upgrade_product(params = {})
          Client.new(params).upgrade_product(params[:product_ident])
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

  end
end
