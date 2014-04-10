module SUSE
  module Toolkit
    # utility methods
    module Utilities

      include ::Net::HTTPHeader

      def token_auth(token)
        "Token token=#{token}"
      end

      def basic_auth
        system_credentials = SUSE::Connect::Credentials.read(Credentials::GLOBAL_CREDENTIALS_FILE)
        username = system_credentials.username
        password = system_credentials.password

        if username && password
          basic_encode(username, password)
        else
          raise SUSE::Connect::CannotBuildBasicAuth, 'cannot get proper username and password'
        end

      rescue
        raise SUSE::Connect::CannotBuildBasicAuth, 'cannot get proper username and password'
      end

    end
  end
end
