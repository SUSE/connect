module SUSE
  module Toolkit
    # utility methods
    module Utilities

      include ::Net::HTTPHeader

      def token_auth(token)
        raise SUSE::Connect::CannotBuildTokenAuth, 'token auth requested, but no token provided' unless token
        "Token token=#{token}"
      end

      def basic_auth

        username, password = SUSE::Connect::System.credentials

        if username && password
          basic_encode(username, password)
        else
          raise SUSE::Connect::CannotBuildBasicAuth, 'cannot get proper username and password'
        end

      end

    end
  end
end
