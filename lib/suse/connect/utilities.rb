# utility methods
module SUSE
  module Connect
    class Utilities
      def token_auth
        raise CannotBuildTokenAuth, 'token auth requested, but no token provided' unless options[:token]
        "Token token=#{options[:token]}"
      end

      def basic_auth

        username, password = System.credentials

        if username && password
          basic_encode(username, password)
        else
          raise CannotBuildBasicAuth, 'cannot get proper username and password'
        end

      end

    end
  end
end
