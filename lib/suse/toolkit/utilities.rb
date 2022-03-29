module SUSE
  module Toolkit
    # utility methods
    module Utilities
      include ::Net::HTTPHeader

      # Response header that might be set as a response for a given request.
      # This should, in turn, be saved into the credentials file.
      SYSTEM_TOKEN_HEADER = 'System-Token'.freeze

      def token_auth(token)
        "Token token=#{token}"
      end

      def system_auth
        system_credentials = SUSE::Connect::Credentials.read(SUSE::Connect::Credentials.system_credentials_file)
        username = system_credentials.username
        password = system_credentials.password

        if username && password
          { encoded: basic_encode(username, password), token: system_credentials.system_token }
        else
          raise
        end
      rescue
        raise SUSE::Connect::CannotBuildBasicAuth,
              "\nCannot read username and password from #{SUSE::Connect::Credentials.system_credentials_file}. Please activate your system first."
      end
    end
  end
end
