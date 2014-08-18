module SUSE
  module Connect
    class MalformedSccCredentialsFile < StandardError; end
    class MissingSccCredentialsFile < StandardError; end
    class FileError < StandardError; end
    class CannotBuildBasicAuth < StandardError; end
    class CannotBuildTokenAuth < StandardError; end
    class TokenNotPresent < StandardError; end
    class CannotDetectBaseProduct < StandardError; end
    class SystemCallError < StandardError; end

    # Basic error for API interactions. Collects HTTP response (which includes
    # status code and response body) for future showing to user via {Cli}
    class ApiError < StandardError
      attr_accessor :response, :message

      # @param response [Net::HTTPResponse] the HTTP response error returned
      # by API request
      def initialize(response)
        @response = response
      end

      def code
        @response.code
      end

      def message
        @response.body['localized_error']
      end
    end

    # Error for interactions with zypper.  Collects process exit status for
    # later reporting
    class ZypperError < StandardError
      attr_accessor :exitstatus, :output
      def initialize(exitstatus, output)
        @exitstatus = exitstatus
        @output = output
      end
    end
  end
end
