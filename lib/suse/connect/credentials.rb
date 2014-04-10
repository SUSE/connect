
# TODO: the global rubocop style does not match the SUSE style guide
# see https://github.com/SUSE/style-guides/blob/master/Ruby.md#strings
# rubocop:disable StringLiterals

require "fileutils"
require "pathname"

# TODO: use a logger
# require "logger"

require "suse/connect/errors"

module SUSE
  module Connect

    # Class for handling credentials
    # It can read the global credentials (/etc/zypp/credentials.d/SCCcredentials)
    # or the services credentials
    class Credentials
      #      include Logger

      # the default location of credential files
      DEFAULT_CREDENTIALS_DIR = "/etc/zypp/credentials.d"
      # global credentials
      GLOBAL_CREDENTIALS_FILE = File.join(DEFAULT_CREDENTIALS_DIR, "SCCcredentials")

      attr_reader :username, :password
      attr_accessor :file

      def initialize(user, password, file = nil)
        @username = user
        @password = password
        @file = file
      end

      def self.read(file)
        raise MissingSccCredentialsFile unless File.exist?(file)

        content = File.read(file)

        user, passwd = parse(content)
        #        log.info("Reading credentials from #{file}")
        credentials = Credentials.new(user, passwd, file)
        #        log.debug("Read credentials: #{credentials}")
        credentials
      end

      # Write credentials to a file
      def write
        raise "Invalid filename" if file.nil? || file.empty?
        filename = Pathname.new(file).absolute? ? file : File.join(DEFAULT_CREDENTIALS_DIR, file)

        # create the target directory if it is missing
        dirname = File.dirname(filename)
        FileUtils.mkdir_p(dirname) unless File.exist?(dirname)

        #        log.info("Writing credentials to #{filename}")
        #        log.debug("Credentials to write: #{self}")
        # make sure only the owner can read the content
        File.write(filename, serialize, :perm => 0600)
      end

      # security - override to_s to avoid writing the password to log
      def to_s
        "#<#{self.class}:#{format("%0#16x", object_id)} " \
          "@username=#{username.inspect}, @password=\"[FILTERED]\", @file=#{file.inspect}>"
      end

      private

      # parse a credentials file content
      def self.parse(input)
        if input.match(/^\s*username\s*=\s*(\S+)\s*$/)
          user = Regexp.last_match(1)
        else
          raise MalformedSccCredentialsFile, "Cannot parse credentials file"
        end

        if input.match(/^\s*password\s*=\s*(\S+)\s*$/)
          passwd = Regexp.last_match(1)
        else
          raise MalformedSccCredentialsFile, "Cannot parse credentials file"
        end

        [user,  passwd]
      end

      # serialize the credentials for writing to a file
      def serialize
        "username=#{username}\npassword=#{password}\n"
      end

    end
  end
end
