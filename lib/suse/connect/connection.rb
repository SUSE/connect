require 'openssl'
require 'net/http'
require 'ostruct'
require 'json'

module SUSE
  module Connect
    # Establishing a connection to SCC REST API and calling
    class Connection
      include Logger

      VERB_TO_CLASS = {
        :get    => Net::HTTP::Get,
        :post   => Net::HTTP::Post,
        :put    => Net::HTTP::Put,
        :delete => Net::HTTP::Delete
      }

      attr_accessor :debug, :http, :auth, :language

      def initialize(endpoint, language: nil, insecure: false, debug: false, verify_callback: nil)
        uri              = URI.parse(endpoint)
        http             = Net::HTTP.new(uri.host, uri.port)
        if http.proxy?
          http.proxy_user = SUSE::Toolkit::CurlrcDotfile.new.username
          http.proxy_pass = SUSE::Toolkit::CurlrcDotfile.new.password
        end
        http.use_ssl     = uri.is_a? URI::HTTPS
        http.verify_mode = insecure ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
        http.read_timeout = 60

        @http            = http
        @http.set_debug_output(STDERR) if debug
        @language        = language
        @debug = debug
        self.verify_callback = verify_callback
      end

      VERB_TO_CLASS.keys.each do |name_for_method|
        define_method name_for_method do |path, auth: nil, params: {} |
          @auth = auth
          response = json_request(name_for_method.downcase.to_sym, path, params)

          unless response.success
            error = ApiError.new(response)
            raise(error, error.message)
          end

          response
        end
      end

      private

      def json_request(method, path, params = {})
        request                    = VERB_TO_CLASS[method].new(path)
        add_headers(request)

        request.body               = params.to_json unless params.empty?
        response                   = @http.request(request)
        body                       = JSON.parse(response.body) if response.body

        OpenStruct.new(
          code: response.code.to_i,
          headers: response.to_hash,
          body: body,
          success: response.is_a?(Net::HTTPSuccess)
        )
      end

      def add_headers(request)
        request['Authorization']   = auth
        request['Content-Type']    = 'application/json'
        request['Accept']          = "application/json,application/vnd.scc.suse.com.#{SUSE::Connect::Api::VERSION}+json"
        request['Accept-Language'] = language
        # no gzip compression for easier debugging
        request['Accept-Encoding'] = 'identity' if debug
        request['User-Agent']      = "SUSEConnect/#{SUSE::Connect::VERSION}"
      end

      # set a verify_callback to HTTP object, use a custom callback
      # or the default if not set
      def verify_callback=(callback)
        if callback
          log.debug "Using custom verify_callback: #{callback.source_location.map(&:to_s).join(':')}"
          http.verify_callback = callback
        else
          # log some error details which are not included in the SSL exception
          http.verify_callback = lambda do |verify_ok, context|
            unless verify_ok
              log.error "SSL verification failed: #{context.error_string}"
              log.error "Certificate issuer: #{context.current_cert.issuer}"
              log.error "Certificate subject: #{context.current_cert.subject}"
            end
            verify_ok
          end
        end
      end

    end
  end
end
