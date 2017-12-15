require 'optparse'

module SUSE
  module Connect
    # @note please take a look at https://github.com/SUSE/connect/wiki/SCC-API-(Implemented) for more detailed protocol
    #       description.
    #
    # SCC's API provides a RESTful API interface. This essentially means that you can send an HTTP request
    # (GET, PUT/PATCH, POST, or DELETE) to an endpoint, and you'll get back a JSON representation of the resource(s)
    # (including children) in return. The Connect API is located at https://scc.suse.com/connect.
    class Api
      # Set desired API version and forward it in accept headers (see connection.rb#json_request)
      VERSION = 'v4'

      # Returns a new instance of SUSE::Connect::Api
      #
      # @param client [SUSE::Connect::Client] client instance
      # @return [SUSE::Connect::Api] api object to call SCC API
      def initialize(client)
        @client     = client
        @connection = Connection.new(
          client.config.url,
          language:        client.config.language,
          insecure:        client.config.insecure,
          verify_callback: client.config.verify_callback,
          debug:           client.config.debug
        )
      end

      # Checks if API endpoint is up-to-date, useful when dealing with RegistrationProxy errors
      #
      # @returns: `true` if the up-to-date SCC API detected, `false` otherwise
      def up_to_date?
        @connection.get('/connect/repositories/installer')
        # Should fail in any case. 422 error means that the endpoint is there and working right;
        # for older Registration Proxies 404 is typically expected.
        # In the unlikely case this call succeeds - the API is not implemented right, so endpoint is not up-to-date.
        return false
      rescue ApiError => e
        return e.code == 422
      rescue JSON::ParserError
        # Even older Registration Proxies can return html instead of json when 404 is encountered
        return false
      end

      # Announce a system to SCC.
      # @note https://github.com/SUSE/connect/wiki/SCC-API-(Implemented)#wiki-announce-system
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      # In this case we expect Token authentication where token is a registration code e.g. 'Token token=<REGCODE>'
      # @return [OpenStruct] responding to #body(response from SCC), #code(natural HTTP response code) and #success.
      #
      def announce_system(auth, distro_target = nil, instance_data = nil, namespace = nil)
        payload = {
          hostname:      System.hostname,
          hwinfo:        System.hwinfo,
          distro_target: distro_target || Zypper.distro_target
        }

        payload[:instance_data] = instance_data if instance_data
        payload[:namespace] = namespace if namespace

        @connection.post('/connect/subscriptions/systems', auth: auth, params: payload)
      end

      # Re-send the system's hardware info to SCC.
      # @note https://github.com/SUSE/connect/wiki/SCC-API-%28Implemented%29#update-system
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expect Base64 encoded string with login and password
      # @return [OpenStruct] responding to #body(response from SCC), #code(natural HTTP response code) and #success.
      #
      def update_system(auth, distro_target = nil, instance_data = nil, namespace = nil)
        payload = {
          hostname:      System.hostname,
          hwinfo:        System.hwinfo,
          distro_target: distro_target || Zypper.distro_target
        }
        payload[:instance_data] = instance_data if instance_data
        payload[:namespace] = namespace if namespace

        @connection.put('/connect/systems', auth: auth, params: payload)
      end

      # Activate a product, consuming an entitlement, and receive the service for this
      # combination of subscription, installed product, and architecture.
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expect Base64 encoded string with login and password
      # @param product [SUSE::Connect::Remote::Product] product to be activated
      # @param email [String] Adds the user to the respective organization or
      #   sends an SCC invitation.
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      def activate_product(auth, product, email = nil)
        payload = {
          identifier:   product.identifier,
          version:      product.version,
          arch:         product.arch,
          release_type: product.release_type,
          token:        @client.config.token,
          email:        email
        }
        @connection.post('/connect/systems/products', auth: auth, params: payload)
      end

      # Deactivate a product, freeing a slot for another activation. Returns the service
      # associated to the product.
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expect Base64 encoded string with login and password
      # @param product [SUSE::Connect::Remote::Product] product to be deactivated
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      def deactivate_product(auth, product)
        payload = {
          identifier:   product.identifier,
          version:      product.version,
          arch:         product.arch,
          release_type: product.release_type
        }
        @connection.delete('/connect/systems/products', auth: auth, params: payload)
      end

      # Upgrade a product and receive the updated service for the system.
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expect Base64 encoded string with login and password
      # @param product [SUSE::Connect::Remote::Product] product
      def upgrade_product(auth, product)
        @connection.put('/connect/systems/products', auth: auth, params: product.to_params)
      end

      # Downgrade a product and receive the updated service for the system.
      # INFO: Upgrade and Downgrade methods point to the same API endpoint
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expect Base64 encoded string with login and password
      # @param product [SUSE::Connect::Remote::Product] product
      alias_method :downgrade_product, :upgrade_product

      # Synchronize activated system products with the registration server (SCC).
      # Expects product list parameter to be a list of hashes.
      #
      # @param products [Array] product with identifier, arch and version defined
      #
      def synchronize(auth, products)
        @connection.post('/connect/systems/products/synchronize', auth: auth, params: { products: products.map(&:to_params) })
      end

      # Show details of an (activated) product including repositories and available extensions
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def show_product(auth, product)
        @connection.get('/connect/systems/products', auth: auth, params: product.to_params)
      end

      # Deregister/unregister a system
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expect Base64 encoded string with login and password
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def deregister(auth)
        @connection.delete('/connect/systems', auth: auth)
      end

      # Gets a list of services known by the system with system credentials
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expect Base64 encoded string with login and password
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def system_services(auth)
        @connection.get('/connect/systems/services', auth: auth)
      end

      # Gets a list of subscriptions known by system authenticated with system credentials
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expect Base64 encoded string with login and password
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def system_subscriptions(auth)
        @connection.get('/connect/systems/subscriptions', auth: auth)
      end

      # Gets a list of activations known by system authenticated with system credentials
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expect Base64 encoded string with login and password
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def system_activations(auth)
        @connection.get('/connect/systems/activations', auth: auth)
      end

      # Lists all available upgrade paths for a given list of products
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expect Base64 encoded string with login and password
      # @param [Array <Remote::Product>] a list of producs
      # @param target_base_product [Remote::Product] (optional) a target base
      #   product to upgrade to. Only used by the backend when kind is :offline. Defaults to nil.
      # @param kind [Symbol] (optional) :online or :offline. It specifies whether
      #   the online or the offline migrations are desired. Defaults to :online.
      #
      # @return [Array <Array <Hash>>] the list of possible upgrade paths for the given products,
      #   where each product is represented by a hash with identifier, version, arch and release_type
      def system_migrations(auth, products, kind: :online, target_base_product: nil)
        payload = { installed_products: products.map(&:to_params) }
        payload[:target_base_product] = target_base_product.to_params if target_base_product
        endpoints = {
          online: '/connect/systems/products/migrations',
          offline: '/connect/systems/products/offline_migrations'
        }
        @connection.post(endpoints.fetch(kind), auth: auth, params: payload)
      end

      # List available Installer-Updates repositories for the given product
      #
      # @param product [Remote::Product] list repositories for this product
      #
      # @return [Array <Hash>] list of Installer-Updates repositories
      def list_installer_updates(product)
        @connection.get('/connect/repositories/installer', params: product.to_params)
      end
    end
  end
end
