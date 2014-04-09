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

      # Returns a new instance of SUSE::Connect::Api
      #
      # @param client [SUSE::Connect::Client] client instance
      # @return [SUSE::Connect::Api] api object to call SCC API
      def initialize(client)
        @client     = client
        @connection = Connection.new(
            client.url,
            :insecure => client.options[:insecure],
            :debug => client.options[:debug]
        )
      end

      # Announce a system to SCC.
      # @note https://github.com/SUSE/connect/wiki/SCC-API-(Implemented)#wiki-announce-system
      #
      # @param auth [String] authorizaztion string which will be injected in `Authorization` header in request.
      #   In this case we expect Token authentication where token is a registration code.
      # @return [OpenStruct] responding to #body(response from SCC), #code(natural HTTP response code) and #success.
      #
      def announce_system(auth)
        payload = {
          :hostname      => System.hostname,
          :distro_target => Zypper.distro_target
        }
        @connection.post('/connect/subscriptions/systems', :auth => auth, :params => payload)
      end

      # Activate a product, consuming an entitlement, and receive the updated list of services for the system
      # Find and return the correct list of all available services for this system's combination of subscription,
      # installed product, and architecture.
      #
      # @param auth [String] authorizaztion string which will be injected in `Authorization` header in request.
      #   In this case we expects Base64 encoded string with login and password
      # @param product [Hash] product
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      # @todo TODO: introduce Product class
      def activate_product(auth, product)
        token = product[:token] || @client.options[:token]
        payload = {
          :product_ident => product[:name],
          :product_version => product[:version],
          :arch => product[:arch],
          :release_type => product[:release_type],
          :token => token
        }
        @connection.post('/connect/systems/products', :auth => auth, :params => payload)
      end

      # List all publicly available products. This includes a list of all repositories for each product.
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def products
        @connection.get('/connect/products', :auth => nil)
      end

      # List all addons available for the given system
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def addons(auth, product)
        payload = { :product_ident => product[:name] }
        @connection.get('/connect/systems/products', :auth => auth, :params => payload)
      end

      # Deregister/unregister a system
      #
      # @param auth [String] authorizaztion string which will be injected in `Authorization` header in request.
      #   In this case we expects Base64 encoded string with login and password
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def deregister(auth)
        @connection.delete('/connect/systems/', :auth => auth)
      end
    end
  end
end
