require 'openssl'
require 'net/http'
require 'ostruct'
require 'json'
require 'suse/toolkit/utilities'

module SUSE
  module Connect
    # Establishing a connection to SCC REST API and calling
    class Connection
      include Logger

      VERB_TO_CLASS = {
        get: Net::HTTP::Get,
        post: Net::HTTP::Post,
        put: Net::HTTP::Put,
        delete: Net::HTTP::Delete
      }

      attr_accessor :debug, :http, :auth, :language

      def initialize(endpoint, language: nil, insecure: false, debug: false, verify_callback: nil)
        endpoint         = prefix_protocol(endpoint)
        uri              = URI.parse(endpoint)
        http             = Net::HTTP.new(uri.host, uri.port)
        if http.proxy?
          proxy_address = http.proxy_uri.hostname
          proxy_port = http.proxy_uri.port
          proxy_user = SUSE::Toolkit::CurlrcDotfile.new.username
          proxy_pass = SUSE::Toolkit::CurlrcDotfile.new.password
          log.debug("Using proxy: #{http.proxy_uri}")
          http = Net::HTTP.new(uri.host, uri.port, proxy_address, proxy_port, proxy_user, proxy_pass)
        end
        http.use_ssl     = uri.is_a? URI::HTTPS
        http.verify_mode = insecure ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
        http.read_timeout = 60

        @http            = http
        @language        = language
        @debug           = debug
        @http.set_debug_output(STDERR) if debug
        self.verify_callback = verify_callback
      end

      VERB_TO_CLASS.each_key do |name_for_method|
        define_method name_for_method do |path, auth: nil, params: {}|
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

      def path_with_params(path, params)
        return path if params.nil? || params.empty?
        encoded_params = URI.encode_www_form(params)
        [path, encoded_params].join('?')
      end

      def prefix_protocol(endpoint)
        if endpoint[%r{^(http|https):\/\/}]
          endpoint
        else
          "https://#{endpoint}"
        end
      end

      def json_request(method, path, params = {})
        # for :get requests, the params need to go to the url, for other requests into the body
        if method == :get
          request = VERB_TO_CLASS[method].new(path_with_params(path, params))
        else
          request = VERB_TO_CLASS[method].new(path)
          request.body = params.to_json unless params.nil? || params.empty?
        end
        add_headers(request)

        response      = @http.request(request)
        response_body = JSON.parse(response.body) unless response.body.to_s.empty?

        update_system_token!(response)

        OpenStruct.new(
          code: response.code.to_i,
          headers: response.to_hash,
          body: response_body,
          http_message: response.message,
          success: response.is_a?(Net::HTTPSuccess)
        )
      rescue Zlib::Error
        raise SUSE::Connect::NetworkError, 'Check your network connection and try again. If it keeps failing, report a bug.'
      end

      # Given an HTTP response, try to update the credentials file with the
      # given 'System-Token' header.
      def update_system_token!(response)
        return unless System.credentials?

        value = response.to_hash[SUSE::Toolkit::Utilities::SYSTEM_TOKEN_HEADER.downcase]
        token = value.first.strip unless value.nil? || value.first.nil?
        return if token.nil? || token.empty?

        creds = System.credentials
        creds.system_token = token
        creds.write
      end

      def add_headers(request)
        # The authorization might be a hash, which means that both an encoded
        # authorization and a system token are given.
        if auth.is_a?(Hash)
          request['Authorization'] = auth[:encoded]
          # Note that `Net/HTTP` ignore headers with an empty value (i.e. nil or
          # ''). Thus, if there is no system token yet for this system, assign a
          # string with at least one space character, so it's not ignored but
          # perceived as empty by the server.
          request[SUSE::Toolkit::Utilities::SYSTEM_TOKEN_HEADER] = auth[:token] || ' '
        else
          request['Authorization'] = auth
        end

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
