module SUSE
  module Connect
    module YaST
    end

      def announce_system
        response = @api.announce_system(Utilities::token_auth)
        body = response.body
        Zypper.write_base_credentials(body['login'], body['password'])
      end

      def activate_product(product)
        response = @api.activate_subscription(Utilities::basic_auth, product)
        service = Service.new(response.body['sources'], response.body['enabled'], response.body['norefresh'])
        System.add_service(service)
      end

  end
end
