require 'openssl'
require 'net/http'
require 'ostruct'
require 'json'

module SUSE
  module Connect
    # Establishing a connection to SCC REST API and calling
    class Connection

      VERB_TO_CLASS = {
        :get    => Net::HTTP::Get,
        :post   => Net::HTTP::Post,
        :put    => Net::HTTP::Put,
        :delete => Net::HTTP::Delete
      }

      attr_accessor :http, :auth, :language

      def initialize(endpoint, language: nil, insecure: false, debug: false)
        uri              = URI.parse(endpoint)
        http             = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl     = uri.is_a? URI::HTTPS
        http.verify_mode = insecure ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
        @http            = http
        @http.set_debug_output(STDERR) if debug
        @language        = language
      end

      VERB_TO_CLASS.keys.each do |name_for_method|
        define_method name_for_method do |path, auth: nil, params: {} |
          @auth = auth
          response = json_request(name_for_method.downcase.to_sym, path, params)
          raise(ApiError.new(response.code, response.body)) unless response.success
          response
        end
      end

      private

      def json_request(method, path, params = {})
        request                    = VERB_TO_CLASS[method].new(path)
        request['Authorization']   = auth
        request['Content-Type']    = 'application/json'
        request['Accept']          = 'application/json'
        request['Accept-Language'] = language
        request.body               = params.to_json unless params.empty?
        response                   = @http.request(request)
        body                       = JSON.parse(response.body)
        OpenStruct.new(
            :code => response.code.to_i,
            :body => body,
            :success => response.is_a?(Net::HTTPSuccess)
        )
      end

    end
  end
end
