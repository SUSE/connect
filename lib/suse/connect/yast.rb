module SUSE
  module Connect

    # YaST class provides methods emulating SCC's API.
    # YaST call this class from:
    # https://github.com/yast/yast-registration/blob/master/src/lib/registration/registration.rb
    class YaST
      # Define a constants which point to the constants used in SUSEConnect
      DEFAULT_CONFIG_FILE = SUSE::Connect::Config::DEFAULT_CONFIG_FILE
      DEFAULT_URL = SUSE::Connect::Config::DEFAULT_URL
      DEFAULT_CREDENTIALS_DIR = SUSE::Connect::Credentials::DEFAULT_CREDENTIALS_DIR
      GLOBAL_CREDENTIALS_FILE = SUSE::Connect::Credentials::GLOBAL_CREDENTIALS_FILE
      SERVER_CERT_FILE = SUSE::Connect::SSLCertificate::SERVER_CERT_FILE
      UPDATE_CERTIFICATES = SUSE::Connect::SSLCertificate::UPDATE_CERTIFICATES

      class << self
        # Announces the system to SCC / the registration server.
        # Expects a token / regcode to identify the correct subscription.
        # Additionally, distro_target should be set to avoid calls to Zypper.
        # Returns the system credentials from SCC.
        #
        # @param [Hash] client_params parameters to instantiate {Client}
        # @param [String] distro_target desired distro target
        #
        # @return [Array <String>] SCC / system credentials - login and password tuple
        def announce_system(client_params = {}, distro_target = nil)
          config = SUSE::Connect::Config.new.merge!(client_params)
          Client.new(config).announce_system(distro_target)
        end

        # Updates the systems hardware info on the server
        # @param [Hash] client_params parameters to instantiate {Client}
        # @param [String] distro_target desired distro target
        #
        # @return [Array <String>] SCC / system credentials - login and password tuple
        def update_system(client_params = {}, distro_target = nil)
          config = SUSE::Connect::Config.new.merge!(client_params)
          Client.new(config).update_system(distro_target)
        end

        # Activates a product on SCC / the registration server.
        # Expects product_ident parameter to be a hash identifying the product.
        # Requires a token / regcode except for free products/extensions.
        # Returns a service object for the activated product.
        #
        # @param [OpenStruct] product with identifier, arch and version defined
        # @param [Hash] client_params parameters to instantiate {Client}
        # @param [String] email email to which this activation should be connected to
        #
        # @return [Service] Service
        def activate_product(product, client_params = {}, email = nil)
          config = SUSE::Connect::Config.new.merge!(client_params)
          Client.new(config).activate_product(product, email)
        end

        # Upgrades a product on SCC / the registration server.
        # Expects product_ident parameter to be a hash identifying the new product.
        # Token / regcode is not required. The new product needs to be available to the regcode the old
        # product was registered with, or be a free product.
        # Returns a service object for the new activated product.
        #
        # @param [OpenStruct] product with identifier, arch and version defined
        # @param [Hash] client_params parameters to instantiate {Client}
        #
        # @return [Service] Service
        def upgrade_product(product, client_params = {})
          config = SUSE::Connect::Config.new.merge!(client_params)
          Client.new(config).upgrade_product(product)
        end

        # Downgrades a product on SCC / the registration server.
        # Expects product_ident parameter to be a hash identifying the new product.
        # Token / regcode is not required. The new product needs to be available to the regcode the old
        # product was registered with, or be a free product.
        # Returns a service object for the new activated product.
        #
        # @param [OpenStruct] product with identifier, arch and version defined
        # @param [Hash] client_params parameters to instantiate {Client}
        #
        # @return [Service] Service
        alias_method :downgrade_product, :upgrade_product

        # Synchronize activated system products with registration server.
        #
        # @param [OpenStruct] products - list of activated system products with identifier, arch and version defined
        # @param [Hash] client_params parameters to instantiate {Client}
        def synchronize(products, client_params = {})
          config = SUSE::Connect::Config.new.merge!(client_params)
          Client.new(config).synchronize(products)
        end

        # Reads credentials file.
        # Returns the credentials object with login, password and credentials file
        #
        # @param [String] Path to credentials file - defaults to /etc/zypp/credentials.d/SCCcredentials
        #
        # @return [OpenStruct] Credentials object as openstruct
        def credentials(credentials_file = GLOBAL_CREDENTIALS_FILE)
          Credentials.read(credentials_file).to_openstruct
        end

        # Creates the system or zypper service credentials file with given login and password.
        # Returns the number of bytes written.
        #
        # @param [String] system login - return value of announce_system method
        # @param [String] system password - return value of announce_system method
        # @param [String] credentials_file - defaults to /etc/zypp/credentials.d/SCCcredentials
        #
        # @return [Integer] number of written bytes
        def create_credentials_file(login, password, credentials_file = GLOBAL_CREDENTIALS_FILE)
          Credentials.new(login, password, credentials_file).write
        end

        # Lists all available products for a system.
        # Accepts a parameter product_ident, which scopes the result set down to all
        # products for the system that are extensions to the specified product.
        # Gets the list from SCC and returns them.
        #
        # @param [OpenStruct] product to list extensions for
        # @param [Hash] client_params parameters to instantiate {Client}
        #
        # @return [OpenStruct] {Product} from registration server with all extensions included
        def show_product(product, client_params = {})
          config = SUSE::Connect::Config.new.merge!(client_params)
          Client.new(config).show_product(product).to_openstruct
        end

        # Checks if the given product is already activated in SCC
        # @param [OpenStruct] product
        # @param [Hash] client_params parameters to instantiate {Client}
        #
        # @return Boolean
        def product_activated?(product, client_params = {})
          return false unless SUSE::Connect::System.credentials?
          status(client_params).activated_products.map(&:to_openstruct).include?(product)
        end

        # Returns activated products on the system
        # @param [Hash] client_params parameters to instantiate {Client}
        # @return [Array <OpenStruct>] the list of activated products
        def activated_products(client_params = {})
          config = SUSE::Connect::Config.new.merge!(client_params)
          Status.new(config).activated_products.map(&:to_openstruct)
        end

        # Lists all available upgrade paths for a given list of products
        # Accepts an array of products, and returns an array of possible
        # upgrade paths. An upgrade path is a list of products that may
        # be upgraded.
        #
        # @param [Array <OpenStruct>] the list of currently installed {Product}s in the system
        # @param [Hash] client_params parameters to instantiate {Client}
        #
        # @return [Array <Array <OpenStruct>>] the list of possible upgrade paths for the given {Product}s,
        #   where an upgrade path is an array of Remote::Product object.
        def system_migrations(products, client_params = {})
          config = SUSE::Connect::Config.new.merge!(client_params)
          Client.new(config).system_migrations(products).map {|a| a.map(&:to_openstruct) }
        end

        # Writes the config file with the given parameters, overwriting any existing contents
        # Only persistent connection parameters (url, insecure) are written by this method
        # Regcode, language, debug etc are not
        # @param [Hash] client_params
        #  - :insecure [Boolean]
        #  - :url [String]
        def write_config(client_params = {})
          config = SUSE::Connect::Config.new.merge!(client_params)
          config.write!
        end

        # Adds given certificate to trusted
        # @param certificate [OpenSSL::X509::Certificate]
        def import_certificate(certificate)
          SUSE::Connect::SSLCertificate.import(certificate)
        end

        # Provides SHA-1 fingerprint of given certificate
        # @param certificate [OpenSSL::X509::Certificate]
        def cert_sha1_fingerprint(certificate)
          SUSE::Connect::SSLCertificate.sha1_fingerprint(certificate)
        end

        # Provides SHA-256 fingerprint of given certificate
        # @param certificate [OpenSSL::X509::Certificate]
        def cert_sha256_fingerprint(certificate)
          SUSE::Connect::SSLCertificate.sha256_fingerprint(certificate)
        end

        # Provides access to current system status in terms of activated products
        # @param [Hash] client_params parameters to instantiate {Client}
        def status(client_params)
          config = SUSE::Connect::Config.new.merge!(client_params)
          Status.new(config)
        end

      end
    end

  end
end
