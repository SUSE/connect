require 'net/http'
require 'ostruct'
require 'json'

module SUSE
  module Connect
    class Connection

      VERB_TO_CLASS = {
        :get    => Net::HTTP::Get,
        :post   => Net::HTTP::Post,
        :put    => Net::HTTP::Put,
        :delete => Net::HTTP::Delete
      }

      attr_accessor :http, :auth

      def initialize(endpoint:, use_ssl: true, insecure: false)
        uri              = URI.parse(endpoint)
        http             = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl     = use_ssl
        http.verify_mode = insecure ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
        @http            = http
      end

      VERB_TO_CLASS.keys.each do |name_for_method|
        define_method name_for_method do |path, auth: nil, params: {} |
          @auth = auth
          json_request name_for_method.downcase.to_sym, path, params
        end
      end

      private

        def json_request(method, path, params={})
          request                   = VERB_TO_CLASS[method].new(path)
          request['Authorization']  = auth if auth
          request['Content-Type']   = 'application/json'
          request.body              = params.to_json unless params.empty?
          response                  = @http.request(request)
          body                      = JSON.parse(response.body)

          OpenStruct.new(:code => response.code.to_i, :body => body)
        end

    end
  end
end

