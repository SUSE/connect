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
    class UnsupportedStatusFormat < StandardError; end
    class NetworkError < StandardError; end
    class SystemNotRegisteredError < StandardError; end
    class BaseProductDeactivationError < StandardError; end
    class UnsupportedOperation < StandardError; end
    class PingNotAllowed < StandardError; end

    # Basic error for API interactions. Collects HTTP response (which includes
    # status code and response body) for future showing to user via {Cli}
    #
    # Used by YaST already, do not refactor without consulting them!
    # (Error handling: #response, #code, #message, #service)
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

      def message
        return @response.http_message unless @response.body
        return @response.body['error'] unless @response.body.key? 'localized_error'

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
