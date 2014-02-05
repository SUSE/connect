require 'optparse'

module SUSE
  module Connect
    # Place for implementing calls to REST api of SCC
    # Any additional call should live here
    class Api

      def initialize(client)
        @client     = client
        @connection = Connection.new(:endpoint => client.url)
      end

      def announce_system(auth)
        @connection.post('/connect/subscriptions/systems', :auth => auth)
      end

      # TODO: introduce Product class
      def activate_subscription(auth, product)
        raise TokenNotPresent unless @client.options[:token]

        payload = {
            :product_ident => product[:name],
            :product_version => product[:version],
            :arch => product[:arch],
            :token => @client.options[:token]
        }

        @connection.post('/connect/systems/products', :auth => auth, :params => payload)
      end

    end
  end
end
