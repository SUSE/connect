module SUSE
  module Toolkit
    # utility methods
    module Utilities
      include ::Net::HTTPHeader

      def token_auth(token)
        "Token token=#{token}"
      end

      def system_auth
        system_credentials = SUSE::Connect::Credentials.read(SUSE::Connect::Credentials.system_credentials_file)
        username = system_credentials.username
        password = system_credentials.password

        if username && password
          basic_encode(username, password)
        else
          raise
        end

      rescue
        raise SUSE::Connect::CannotBuildBasicAuth,
              "Cannot read username and password from #{SUSE::Connect::Credentials::GLOBAL_CREDENTIALS_FILE}"
      end
    end
  end
end
