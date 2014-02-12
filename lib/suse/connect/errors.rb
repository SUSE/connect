module SUSE
  module Connect
    class MalformedNccCredentialsFile < StandardError; end
    class MissingNccCredentialsFile < StandardError; end
    class CannotBuildBasicAuth < StandardError; end
    class CannotBuildTokenAuth < StandardError; end
    class TokenNotPresent < StandardError; end
    class CannotDetectBaseProduct < StandardError; end

    class ApiError < StandardError
      attr_accessor :code, :body

      def initialize(code:, body:)
        @code, @body = code, body
      end
    end

  end
end
