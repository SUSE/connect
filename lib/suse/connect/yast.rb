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
        # @param [Hash] client_params parameters to instantiate {Client}
        # @param [String] distro_target desired distro target
        #
        # @return [Array <String>] SCC / system credentials - login and password tuple
        def announce_system(client_params = {}, distro_target = nil)
          Client.new(client_params).announce_system(distro_target)
        end

        # Activates a product on SCC / the registration server.
        # Expects product_ident parameter to be a hash identifying the product.
        # Requires a token / regcode except for free products/extensions.
        # Returns a service object for the activated product.
        #
        # @param [Remote::Product] product with identifier, arch and version defined
        # @param [Hash] client_params parameters to instantiate {Client}
        # @param [String] email email to which this activation should be connected to
        #
        # @return [Service] Service
        def activate_product(product, client_params = {}, email = nil)
          Client.new(client_params).activate_product(product, email)
        end

        # Upgrades a product on SCC / the registration server.
        # Expects product_ident parameter to be a hash identifying the new product.
        # Token / regcode is not required. The new product needs to be available to the regcode the old
        # product was registered with, or be a free product.
        # Returns a service object for the new activated product.
        #
        # @param [Remote::Product] product with identifier, arch and version defined
        # @param [Hash] client_params parameters to instantiate {Client}
        #
        # @return [Service] Service
        def upgrade_product(product, client_params = {})
          Client.new(client_params).upgrade_product(product)
        end

        # Lists all available products for a system.
        # Accepts a parameter product_ident, which scopes the result set down to all
        # products for the system that are extensions to the specified product.
        # Gets the list from SCC and returns them.
        #
        # @param product [Remote::Product] product to list extensions for
        #
        # @return [Product] {Product}s from registration server with all extensions included
        def show_product(product, client_params  = {})
          Client.new(client_params).show_product(product)
        end

        # Writes the config file with the given parameters, overwriting any existing contents
        # Only persistent connection parameters (url, insecure) are written by this method
        # Regcode, language, debug etc are not
        # @param [Hash] client_params
        #  - :insecure [Boolean]
        #  - :url [String]
        def write_config(client_params = {})
          Client.new(client_params).write_config
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

      end
    end

  end
end
