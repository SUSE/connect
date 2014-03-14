module SUSE
  module Toolkit
    # Provides basic system calls interface
    module SystemCalls

      def call(command)
        system(command) ? true : Logger.error("command `#{command}` failed")
      end

      def call_with_output(command)
        `#{command}`.chomp
      end

      def write_credentials_file(login, password, filename)
        credentials_dir = SUSE::Connect::ZYPPER_CREDENTIALS_DIR
        Dir.mkdir(credentials_dir) unless Dir.exists?(credentials_dir)
        credentials_file = File.join(credentials_dir, filename)

        begin
          file = File.open(credentials_file, 'w')
          file.puts("username=#{sccized_login(login)}")
          file.puts("password=#{password}")
        rescue IOError => e
          Logger.error(e.message)
        ensure
          file.close if file
        end

      end
    end
  end
end
