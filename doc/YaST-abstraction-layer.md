See [yast.rb](../../master/lib/suse/connect/yast.rb) for more details.

## Implemented methods

- [announce system](#announce-system)
- [update system](#update-system)
- [activate product](#activate-product)
- [upgrade product](#upgrade-product)
- [downgrade product](#downgrade-product)
- [synchronize](#synchronize)
- [show product](#show-product)
- [check product activation](#product-activated?)
- [system migrations](#system-migrations)
- [activated_products](#activated-products)
- [add service](#add-service)
- [remove service](#remove-service)
- [read credentials](#credentials)
- [write credentials](#create-credentials-file)
- [write config](#write-config)
- [import certificate](#import-certificate)
- [show sha1 fingerprint](#cert-sha1-fingerprint)
- [show sha256 fingerprint](#cert-sha256-fingerprint)
- [system status](#status)

## YaST constants
      # Define a constants which point to the constants used in SUSEConnect
      DEFAULT_CONFIG_FILE = SUSE::Connect::Config::DEFAULT_CONFIG_FILE
      DEFAULT_URL = SUSE::Connect::Config::DEFAULT_URL
      DEFAULT_CREDENTIALS_DIR = SUSE::Connect::Credentials::DEFAULT_CREDENTIALS_DIR
      GLOBAL_CREDENTIALS_FILE = SUSE::Connect::Credentials::GLOBAL_CREDENTIALS_FILE
      SERVER_CERT_FILE = SUSE::Connect::SSLCertificate::SERVER_CERT_FILE
      UPDATE_CERTIFICATES = SUSE::Connect::SSLCertificate::UPDATE_CERTIFICATES

### <a name="announce-system">Announce system</a>
#### announce_system(client_params = {}, distro_target = nil)
        # Announces the system to SCC / the registration server.
        # Expects a token / regcode to identify the correct subscription.
        # Additionally, distro_target should be set to avoid calls to Zypper.
        # Returns the system credentials from SCC.
        #
        # @param [Hash] client_params parameters to instantiate {Client}
        # @param [String] distro_target desired distro target
        #
        # @return [Array <String>] SCC / system credentials - login and password tuple


### <a name="update-system">Update system</a>
#### update_system(client_params = {}, distro_target = nil)
        # Updates the systems hardware info on the server
        # @param [Hash] client_params parameters to instantiate {Client}
        # @param [String] distro_target desired distro target
        #
        # @return [Array <String>] SCC / system credentials - login and password tuple

### <a name="activate-product">Activate product</a>
#### activate_product(product, client_params = {}, email = nil)
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

### <a name="upgrade-product">Upgrade product</a>
#### upgrade_product(product, client_params = {})
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

### <a name="downgrade-product">Downgrade product (alias method for upgrade_product, uses the same endpoint)</a>
#### downgrade_product(product, client_params = {})
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

### <a name="synchronize">Synchronize</a>
#### synchronize(products, client_params = {})
        # Synchronize activated system products with registration server.
        #
        # @param [OpenStruct] products - list of activated system products
        # @param [Hash] client_params parameters to instantiate {Client}

### <a name="show-product">Show product</a>
#### show_product(product, client_params = {})
        # Lists all available products for a system.
        # Accepts a parameter product_ident, which scopes the result set down to all
        # products for the system that are extensions to the specified product.
        # Gets the list from SCC and returns them.
        #
        # @param [OpenStruct] product to list extensions for
        # @param [Hash] client_params parameters to instantiate {Client}
        #
        # @return [OpenStruct] {Product} from registration server with all extensions included


### <a name="product-activated?">Check product activation</a>
#### product_activated?(product, client_params = {})
        # Checks if the given product is already activated in SCC
        # @param [OpenStruct] product
        # @param [Hash] client_params parameters to instantiate {Client}
        #
        # @return Boolean


### <a name="system-migrations">System migrations</a>
#### system_migrations(products, client_params = {})
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


### <a name="activated-products">Activated products</a>
#### activated_products(client_params = {})
        # Returns activated products on the system
        # @param [Hash] client_params parameters to instantiate {Client}
        # @return [Array <OpenStruct>] the list of activated products


### <a name="credentials">Read credentials</a>
#### credentials(credentials_file = GLOBAL_CREDENTIALS_FILE)
        # Reads credentials file.
        # Returns the credentials object with login, password and credentials file
        #
        # @param [String] Path to credentials file - defaults to /etc/zypp/credentials.d/SCCcredentials
        #
        # @return [OpenStruct] Credentials object as openstruct

### <a name="create-credentials-file">Write credentials</a>
#### create_credentials_file(login, password, credentials_file = GLOBAL_CREDENTIALS_FILE)
        # Creates the system or zypper service credentials file with given login and password.
        # Returns the number of bytes written.
        #
        # @param [String] system login - return value of announce_system method
        # @param [String] system password - return value of announce_system method
        # @param [String] credentials_file - defaults to /etc/zypp/credentials.d/SCCcredentials
        #
        # @return [Integer] number of written bytes

### <a name="write-config">Write config</a>
#### write_config(client_params = {})
        # Writes the config file with the given parameters, overwriting any existing contents
        # Only persistent connection parameters (url, insecure) are written by this method
        # Regcode, language, debug etc are not
        # @param [Hash] client_params
        #  - :insecure [Boolean]
        #  - :url [String]


### <a name="import-certificate">Import certificate</a>
#### import_certificate(certificate)
        # Adds given certificate to trusted
        # @param certificate [OpenSSL::X509::Certificate]


### <a name="cert-sha1-fingerprint">Show SHA-1 certificate fingerprint</a>
#### cert_sha1_fingerprint(certificate)
        # Provides SHA-1 fingerprint of given certificate
        # @param certificate [OpenSSL::X509::Certificate]


### <a name="cert-sha256-fingerprint">Show SHA-256 certificate fingerprint</a>
#### cert_sha256_fingerprint(certificate)
        # Provides SHA-256 fingerprint of given certificate
        # @param certificate [OpenSSL::X509::Certificate]


### <a name="status">System status</a>
#### status(client_params)
        # Provides access to current system status in terms of activated products
        # @param [Hash] client_params parameters to instantiate {Client}


## Missing methods
Please add methods you would like to have in this layer
* hallo(name) # Combines the 'Hello' string with given name @return String 'Hello #{name}'
