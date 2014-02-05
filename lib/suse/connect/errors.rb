module SUSE
  module Connect
    class MalformedNccCredentialsFile < StandardError; end
    class MissingNccCredentialsFile < StandardError; end
    class CannotBuildBasicAuth < StandardError; end
    class CannotBuildTokenAuth < StandardError; end
    class TokenNotPresent < StandardError; end
  end
end
