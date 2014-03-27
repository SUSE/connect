# utility methods
module SUSE
  module Connect
    class Utilities
      class << self
        include ::Net::HTTPHeader

        def token_auth(token)
          raise CannotBuildTokenAuth, 'token auth requested, but no token provided' unless token
          "Token token=#{token}"
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
end
