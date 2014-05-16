require 'fileutils'
require 'pathname'

module SUSE
  module Connect

    # Class for handling credentials
    # It can read the global credentials (/etc/zypp/credentials.d/SCCcredentials)
    # or the services credentials
    class Credentials

      include Logger

      DEFAULT_CREDENTIALS_DIR = '/etc/zypp/credentials.d'
      GLOBAL_CREDENTIALS_FILE = File.join(DEFAULT_CREDENTIALS_DIR, 'SCCcredentials')

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
        log.info("Reading credentials from #{file}")
        credentials = Credentials.new(user, passwd, file)
        log.debug("Read credentials: #{credentials}")
        credentials
      end

      def filename
        filename = Pathname.new(file).absolute? ? file : File.join(DEFAULT_CREDENTIALS_DIR, file)
        $root.nil? || $root.empty? ? filename : File.join($root, filename)
      end

      # Write credentials to a file
      def write
        raise 'Invalid filename' if file.nil? || file.empty?
        dirname = File.dirname(filename)
        FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
        log.info("Writing credentials to #{filename}")
        log.debug("Credentials to write: #{self}")
        File.write(filename, serialize, :perm => 0600)
      end

      # security - override to_s to avoid writing the password to log
      def to_s
        contents = {}
        contents[:class]    = self.class
        contents[:id]       = format('%0#16x', object_id)
        contents[:username] = username.inspect
        contents[:password] = '[FILTERED]'.inspect
        contents[:file]     = file.inspect
        format('#<%{class}:%{id} @username=%{username}, @password=%{password}, @file=%{file}>', contents)
      end

      private

      # parse a credentials file content
      def self.parse(input)

        if input.match(/^\s*username\s*=\s*(\S+)\s*$/)
          user = Regexp.last_match(1)
        else
          raise MalformedSccCredentialsFile, 'Cannot parse credentials file'
        end

        if input.match(/^\s*password\s*=\s*(\S+)\s*$/)
          passwd = Regexp.last_match(1)
        else
          raise MalformedSccCredentialsFile, 'Cannot parse credentials file'
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
