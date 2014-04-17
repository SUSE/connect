module SUSE
  module Connect
    class MalformedSccCredentialsFile < StandardError; end
    class MissingSccCredentialsFile < StandardError; end
    class CannotBuildBasicAuth < StandardError; end
    class CannotBuildTokenAuth < StandardError; end
    class TokenNotPresent < StandardError; end
    class CannotDetectBaseProduct < StandardError; end

    # Basic error for API interactions. Collects HTTP response (which includes
    # status code and response body) for future showing to user via {Cli}
    class ApiError < StandardError
      attr_accessor :response

      # @param response [Net::HTTPResponse] the HTTP response error returned
      # by API request
      def initialize(response)
        @response = response
      end

      def code
        @response.code
      end

      def body
        @response.body
      end
    end

  end
end
