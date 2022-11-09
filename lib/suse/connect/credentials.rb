require 'fileutils'
require 'pathname'
require 'suse/toolkit/cast'

module SUSE
  module Connect
    # Class for handling credentials
    # It can read the global credentials (/etc/zypp/credentials.d/SCCcredentials)
    # or the services credentials
    #
    # Used by YaST already, do not refactor without consulting them!
    # (Reading and writing (#read, #write), reading/writing the attributes (#file, #username, #password))
    class Credentials
      include Logger
      include SUSE::Toolkit::Cast

      DEFAULT_CREDENTIALS_DIR = '/etc/zypp/credentials.d'
      GLOBAL_CREDENTIALS_FILE = File.join(DEFAULT_CREDENTIALS_DIR, 'SCCcredentials')

      attr_reader :username, :password
      attr_accessor :system_token, :file

      def initialize(user, password, system_token = nil, file = nil)
        @username = user
        @password = password
        @system_token = system_token
        @file = file
      end

      def self.system_credentials_file
        SUSE::Connect::System.prefix_path(GLOBAL_CREDENTIALS_FILE)
      end

      def self.read(file)
        raise MissingSccCredentialsFile unless File.exist?(file)
        content = File.read(file)
        user, passwd, token = parse(content)
        log.debug("Reading credentials from #{file}")
        credentials = Credentials.new(user, passwd, token, file)
        log.debug("Read credentials: #{credentials.username} : #{credentials.password} : #{credentials.system_token}")
        credentials
      end

      def filename
        default_dir = SUSE::Connect::System.prefix_path(DEFAULT_CREDENTIALS_DIR)
        Pathname.new(file).absolute? ? file : File.join(default_dir, file)
      end

      # Write credentials to a file
      def write
        raise 'Invalid filename' if file.nil? || file.empty?
        dirname = File.dirname(filename)
        FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
        log.debug("Writing credentials to #{filename}")
        log.debug("Credentials to write: #{self}")
        File.write(filename, serialize, perm: 0600)
      end

      # security - override to_s to avoid writing the password to log
      def to_s
        contents = {}
        contents[:class]        = self.class
        contents[:id]           = format('%0#16x', object_id)
        contents[:username]     = username.inspect
        contents[:password]     = '[FILTERED]'.inspect
        contents[:system_token] = system_token.inspect
        contents[:file]         = file.inspect
        format('#<%{class}:%{id} @username=%{username}, @password=%{password}, @system_token=%{system_token}, @file=%{file}>', contents)
      end

      # Returns a hash representation of the object
      def to_h
        { username: username, password: password, system_token: system_token, file: file }
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

        # It's fine to have an empty system_token.
        token = Regexp.last_match(1) if input.match(/^\s*system_token\s*=\s*(\S+)\s*$/)

        [user, passwd, token]
      end

      # serialize the credentials for writing to a file
      # don't serialize the token when it is nil, because it's an unknown
      # attribute for zypp in the service credentials
      def serialize
        content = "username=#{username}\npassword=#{password}\n"
        content += "system_token=#{system_token}\n" if system_token
        content
      end
    end
  end
end
