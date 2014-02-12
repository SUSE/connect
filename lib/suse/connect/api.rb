require 'optparse'

module SUSE
  module Connect
    # Place for implementing calls to REST api of SCC
    # @note it is combined documentation. Providing both SCC API documentation and
    #     this library documentation, which is implementing interaction with it
    # Later on, when we will have additional calls - this class will be transformed to module with separate classes
    # divided by entity interactions. System, Subscription, etc.
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
            :insecure => client.options[:insecure]
        )
      end

      # Announce a system to SCC and consume a subscription. This is the typical first contact of any system with SCC,
      # which triggers a couple of processes:
      #
      # * Register the system with SCC, thereby creating and returning the system's credentials (identifier and secret)
      #   for further access to this API and update repositories.
      #
      # * Store the system's information from the payload in SCC to be able to provide proper counting and additional
      #   functionality through SCC's web page.
      #
      # * Validate subscription specified by the token. E.g. check for expiry date, system limit, hardware requirements,
      #   etc.
      #
      # * Associate the system inside SCC with the subscription.
      #
      # `POST /connect/subscriptions/systems`
      #
      # **Api Parameters:**
      #
      # * Optional:
      #     * `hostname` [String]: The system's hostname can be arbitrary and does not have to be unique.
      #                            It will show up in SCC and serves as a human readable identifier to the user.
      #     * `hwinfo`   [String]: Hardware information used to evaluate a subscription's potential business
      #                            requirements (e.g. counting `sockets`) and to provide additional help
      #                            (e.g. vendor specific repositories).
      #     * `email`    [String]: The user's email address to ensure he will be able to see his this system, when he
      #                            logs into SCC's web frontend.
      #     * `parent`   [String]: The user's email address to ensure he will be able to see his this system, when he
      #                            logs into SCC's web frontend.
      #
      # **Curl Example:**
      #
      # ```
      # curl http://127.0.0.1:3000/connect/subscriptions/systems -H 'Content-Type: application/json' \
      #     -H 'Authorization: Token token="4e4ad427"' -d '{"hostname": "test"}'
      # ```
      #
      # **Example Response**
      #
      # The response will contain the system credentials (login/password) that will get stored on the system in
      # `/etc/zypp/credentials.d/SCCcredentials` to authenticate any subsequent calls to SCC from this system.
      #
      # ```json
      # {
      #    "id":104,
      #    "login":"SCC_<login>",
      #    "password":"<password>",
      #    "created_at":"2014-01-15T10:49:36.124Z",
      #    "updated_at":"2014-01-15T10:49:36.124Z",
      #    "identifier":null,
      #    "hwinfo":null,
      #    "credentials_file":null,
      #    "nnw_system":null,
      #    "hostname":"virtual-system.domain.net",
      #    "registered_at":"2014-01-15T10:49:36.121Z",
      #    "vendor":"SUSE",
      #    "parent_id":null,
      #    "sys_host_id":null
      # }
      # ```
      # @param auth [String] authorizaztion string which will be injected in `Authorization` header in request.
      #   In this case we expect Token authentication where token is a subscription code.
      # @return [OpenStruct] responding to body(response from SCC) and code(natural HTTP response code).
      #
      def announce_system(auth)
        @connection.post('/connect/subscriptions/systems', :auth => auth)
      end

      # Activate a product and receive the services list.
      # Find and return the correct list of all available services for this system's combination of subscription,
      # installed product, and architecture.
      #
      # `POST /connect/systems/products`
      #
      # **Api Parameters:**
      #
      # * Required:
      #     * token (regcode) [String]: opaque string belonging to a subscription
      #     * product_ident   [String]: product name, e.g. `SLES11`
      #     * product_version [String]: product version e.g. `SP11`
      #     * arch            [String]: system architecture, e.g. `x86_64`
      # * Optional:
      #     * email           [String]: The user of this email will be added to the organization if it is known in SCC.
      #                                 (The organization will be evaluated by the given token.). Otherwise the user
      #                                 will receive an email that explains how to proceed.
      #
      # **Curl example**
      #
      # ```
      # curl http://localhost:3000/connect/systems/products  -u<username>:<pass> -H 'Content-Type: application/json' \
      #     -d '{"product_ident": "SLES", "product_version": "11-SP2", "arch": "x86_64", "token": "<token>" }'
      # ```
      # **Example Response:**
      #
      # ```json
      # {
      #   "sources": {
      #    "SUSE_Linux_Enterprise_Server_for_x86_AMD64_Intel64_Activation_Code":
      #       "http://localhost:3000/service\
      #       ?credentials=SUSE_Linux_Enterprise_Server_for_x86_AMD64_Intel64_Activation_Code_credentials"
      #  },
      #    "norefresh": [
      #       "SLES11-SP2-Extension-Store", "SLES10-SP2-Pool"],
      #    "enabled": [
      #       "SLE11-SP2-Debuginfo-Core",
      #       "SLES10-SP4-Online",
      #       "SLE11-WebYaST-SP1-Updates",
      #       "SLE10-SP3-Debuginfo-Updates",
      #       "SLE10-SP4-Debuginfo-Updates",
      #       "SLE11-Debuginfo-Pool",
      #       "SLES11-Updates",
      #       "SLES11-SP1-Updates",
      #       "SLE10-SP3-Debuginfo-Pool",
      #       "SLE10-SP4-Debuginfo-Pool",
      #       "SLES11-SP2-Core",
      #       "SLE11-WebYaST-SP1-Pool",
      #       "SLES10-SP2-Updates",
      #       "SLE11-SP3-Debuginfo-Updates",
      #       "SLES11-SP2-Core"
      #    ]
      # }
      # ```
      #
      # **Errors and return codes:**
      #
      # * `422: "No product specified"`
      # * `422: "No token specified"`
      # * `422: "No valid subscription found"`
      # * `422: "No repositories found for product"`
      #
      # @param auth [String] authorizaztion string which will be injected in `Authorization` header in request.
      #   In this case we expects Base64 encoded string with login and password
      # @param product [Hash] product
      #
      # @todo TODO: introduce Product class
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
