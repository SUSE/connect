require 'pp'

module SUSE
  module Connect
    # System Status object which intention is to provide information about state of currently installed products
    # and subscriptions as known by registration server
    class Status

      attr_reader :client

      def initialize(client)
        @client = client
      end

      def installed_products
        @installed_products ||= products_from_zypper
      end

      def activated_products
        @activated_products ||= products_from_services
      end

      def known_subscriptions
        @known_subscriptions ||= subscriptions_from_server
      end

      private

      def subscriptions_from_server
        @client.system_subscriptions.body.map {|s| Subscription.new(s) }
      end

      def products_from_services
        @client.system_services.body.map {|p| RegServerProduct.new(p['product']) }
      end

      def products_from_zypper
        Zypper.installed_products.map {|p| Product.new(p, true) }
      end

    end

  end

end
