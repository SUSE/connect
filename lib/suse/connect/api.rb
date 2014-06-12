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
      VERSION = 'v1'

      # Returns a new instance of SUSE::Connect::Api
      #
      # @param client [SUSE::Connect::Client] client instance
      # @return [SUSE::Connect::Api] api object to call SCC API
      def initialize(client)
        @client     = client
        @connection = Connection.new(
          client.url,
          :language => client.options[:language],
          :insecure => client.options[:insecure],
          :verify_callback => client.options[:verify_callback],
          :debug => client.options[:debug]
        )
      end

      # Announce a system to SCC.
      # @note https://github.com/SUSE/connect/wiki/SCC-API-(Implemented)#wiki-announce-system
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      # In this case we expect Token authentication where token is a registration code e.g. 'Token token=<REGCODE>'
      # @return [OpenStruct] responding to #body(response from SCC), #code(natural HTTP response code) and #success.
      #
      def announce_system(auth, distro_target = nil)
        payload = {
          :hostname      => System.hostname,
          # TODO: Catch any exceptions Zypper might raise, if YaST has already
          # locked it. Return an understandable Error message to the user.
          :distro_target => distro_target || Zypper.distro_target
        }
        @connection.post('/connect/subscriptions/systems', :auth => auth, :params => payload)
      end

      # Activate a product, consuming an entitlement, and receive the service for this
      # combination of subscription, installed product, and architecture.
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expects Base64 encoded string with login and password
      # @param product [SUSE::Connect::Remote::Product] product to be activated
      # @param email [String] Adds the user to the respective organization or
      #   sends an SCC invitation.
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      def activate_product(auth, product, email = nil)
        payload = {
          :identifier   => product.identifier,
          :version      => product.version,
          :arch         => product.arch,
          :release_type => product.release_type,
          :token        => @client.options[:token],
          :email        => email
        }
        @connection.post('/connect/systems/products', :auth => auth, :params => payload)
      end

      # Upgrade a product and receive the updated service for the system.
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expects Base64 encoded string with login and password
      # @param product [SUSE::Connect::Remote::Product] product
      def upgrade_product(auth, product)
        payload = {
          :identifier   => product.identifier,
          :version      => product.version,
          :arch         => product.arch,
          :release_type => product.release_type
        }
        @connection.put('/connect/systems/products', :auth => auth, :params => payload)
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
        payload = { :product_id => product.identifier }
        @connection.get('/connect/systems/products', :auth => auth, :params => payload)
      end

      # Deregister/unregister a system
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expects Base64 encoded string with login and password
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def deregister(auth)
        @connection.delete('/connect/systems/', :auth => auth)
      end

      # Gets a list of services known by the system with system credentials
      #
      # @param auth [String] authorization string which will be injected in 'Authorization' header in request.
      #   In this case we expects Base64 encoded string with login and password
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def system_services(auth)
        @connection.get('/connect/systems/services', :auth => auth)
      end

      # Gets a list of subscriptions known by system authenticated with system credentials
      #
      # @param auth [String] authorizaztion string which will be injected in 'Authorization' header in request.
      #   In this case we expects Base64 encoded string with login and password
      #
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def system_subscriptions(auth)
        @connection.get('/connect/systems/subscriptions', :auth => auth)
      end

    end
  end
end
