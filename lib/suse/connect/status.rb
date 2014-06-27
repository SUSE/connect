require 'time'
require 'erb'

module SUSE
  module Connect
    # System Status object which intention is to provide information about state of currently installed products
    # and subscriptions as known by registration server
    class Status

      class << self

        attr_writer :client

        def client
          @client ||= Client.new({})
        end

        def activated_products
          @activated_products ||= products_from_activations
        end

        def installed_products
          @installed_products ||= products_from_zypper
        end

        def known_activations
          @known_activations ||= activations_from_server
        end

        def print_product_statuses
          file = File.read File.join(File.dirname(__FILE__), 'templates/text_status.erb')
          template = ERB.new(file, 0, '-<>')
          puts template.result(binding)
        end

        private

        def activations_from_server
          system_activations.map {|s| Remote::Activation.new(s) }
        end

        def products_from_activations
          system_activations.map {|p| Remote::Product.new(p['service']['product']) }
        end

        def products_from_zypper
          Zypper.installed_products
        end

        def product_statuses
          installed_products.map {|p| Zypper::ProductStatus.new(p) }
        end

        def system_activations
          @system_activations ||= client.system_activations.body
        end

      end

    end

  end

end
