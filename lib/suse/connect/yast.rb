module SUSE
  module Connect
    # YaST module provides classes emulating the API of the scc_api gem.
    # 1) Connection is SccApi::Connection
    # 2) ProductServices
    module YaST
      # C&P from scc_api
      # Collection of repository services relevant to a registered product
      # TODO Merge with existing SUSE::Connect::Service
      class ProductServices

        attr_reader :services, :norefresh_repos, :enabled_repos

        # constructor
        # @param services [Array<Service>] services for the product
        # @param norefresh_repos [Array<String>] list of resitories which have
        #  autorefresh enabled by default
        # @param enabled_repos [Array<String>] list of resitories which
        #  are enabled by default
        # @return ProductServices services returned by registration
        def initialize(services, norefresh_repos = [], enabled_repos = [])
          @services = services
          @norefresh_repos = norefresh_repos
          @enabled_repos = enabled_repos
        end

        # create ProductServices from a SCC response
        # @param [Hash] response from SCC server (parsed JSON)
        def self.from_hash(param)
          norefresh = param["norefresh"] || []
          enabled = param["enabled"] || []
          sources = param["sources"] || {}

          services = sources.map do |name, url|
            Service.new(name, url)
          end

          ProductServices.new(services, norefresh, enabled)
        end
      end

      class ProductExtensions
        attr_reader :extensions

        def initialize(extensions)
          @extensions = extensions
        end

        # create ProductExtensions from a SCC response
        # @param [Hash] response from SCC server (parsed JSON)
        def self.from_hash(extensions_response)
          extensions = extensions_response.each do |extension|
            # We do not currently have long_name or description in the SCC response
            Extension.new(extension['name'], '', '', extension['zypper_name'])
          end

          ProductExtensions.new(extensions)
        end
      end

      # Repository service
      class Extension

        attr_reader :short_name, :long_name, :description, :product_ident

        # Constructor
        def initialize(short_name, long_name, description, product_ident)
          @short_name = short_name
          @long_name = long_name
          @description = description
          @product_ident = product_ident
        end
      end

      # Repository service
      class Service

        attr_reader :name, :url

        # Constructor
        # @param name [String] service name
        # @param url [URI, String] service URL
        def initialize(name, url)
          @name = name
          @url = url.is_a?(String) ? URI(url) : url
        end
      end


      # Similar to Client
      class Connection
        def initialize(email, base_regcode, url = "https://scc.suse.com/connect")
          @email = email
          @base_token = base_regcode
          @url = url
          @api = Api.new(self)
        end

        # TODO hwinfo
        def announce_system
          response = @api.announce_system(Utilities.token_auth(@base_token))
          body = response.body
          Zypper.write_base_credentials(body['login'], body['password'])
        end

        # @param product [Hash] product to be activated
        # @param token [String] token/regcode for product being activated
        def activate_product(product, token)
          response = @api.activate_subscription(Utilities.basic_auth, product, token)
          # scc_api does not register the services itself, it returns them to YaST
          ProductServices.from_hash(JSON.parse(response))
        end

        # @param product [Hash] product to query extensions for
        def extensions_for(product)
          response = @api.addons(Utilities.basic_auth, product)
          ProductExtensions.from_hash(JSON.parse(response))
        end
      end
    end
  end
end
