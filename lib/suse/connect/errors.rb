module SUSE
  module Connect
    class MalformedSccCredentialsFile < StandardError; end
    class MissingSccCredentialsFile < StandardError; end
    class CannotBuildBasicAuth < StandardError; end
    class CannotBuildTokenAuth < StandardError; end
    class TokenNotPresent < StandardError; end
    class CannotDetectBaseProduct < StandardError; end

    # Basic error for API interactions. Collects HTTP status codes and response body for future showing to
    # user via {Cli}
    class ApiError < StandardError
      attr_accessor :code, :body

      # @param code [Integer] the HTTP status code reported by API request
      # @param body [Has]     reponse body parsed with JSON
      def initialize(code, body)
        @code, @body = code, body
      end
    end

  end
end
