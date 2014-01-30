module SUSE
  module Connect
    class System

      UUIDFILE                = '/sys/class/dmi/id/product_uuid'
      UUIDGEN_LOCATION        = '/usr/bin/uuidgen'
      SETTINGS_DIRECTORY      = '/etc/suseConnect'
      ZYPPER_CREDENTIALS_DIR  = '/etc/zypp/credentials.d'
      NCC_CREDENTIALS_FILE    = File.join(ZYPPER_CREDENTIALS_DIR, 'NCCcredentials')

      class << self

        def uuid
          if File.exist? UUIDFILE
            file = File.open(UUIDFILE, 'r')
            begin
              client_id = file.gets
            ensure
              file.close
            end
            client_id
          else
            `/usr/bin/uuidgen`.chomp.strip
          end
        end

        def hwinfo
          info = {
              :cpu_type       => `uname -p`,
              :cpu_count      => `grep "processor" /proc/cpuinfo | wc -l`,
              :platform_type  => `uname -i`,
              :hostname       => `hostname`,
          }

          info.values.each(&:chomp!)
          dmidecode = `dmidecode`
          info[:virtualized] = (['vmware', 'virtual machine', 'qemu', 'domu'].any? { |ident| dmidecode.downcase.include? ident }) if dmidecode
          info
        end

        def credentials
          if File.exist?(NCC_CREDENTIALS_FILE)

            file = File.new(NCC_CREDENTIALS_FILE, 'r')

            begin
              lines = file.readlines.map(&:chomp)
              extract_credentials(lines)
            ensure
              file.close
            end

          else
            Logger.error "NCC credentials file not found at: #{NCC_CREDENTIALS_FILE}"
          end
        end

        def registered?
          username = self.credentials.first
          username && username.include?( 'SCC_' )
        end

        private

        ##
        # Assuming structure:
        # username=<32 symbols line>
        # password=<32 symbols line>
        # will raise MalformedNccCredentialsFile if cannot parse
        # provided lines
        def extract_credentials(lines)
          return nil unless lines.count == 2

          begin
            username = divide_credential_tuple lines.select {|line| line =~ /^username=.*/}.first
            password = divide_credential_tuple lines.select {|line| line =~ /^password=.*/}.first
          rescue
            raise MalformedNccCredentialsFile, 'Cannot parse credentials file'
          end

          return username, password
        end

        def divide_credential_tuple(tuple)
          tuple.split('=').last
        end

      end


    end

  end

end
