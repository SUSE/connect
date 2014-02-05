module SUSE
  module Connect
    class System

      UUIDFILE                = '/sys/class/dmi/id/product_uuid'
      UUIDGEN_LOCATION        = '/usr/bin/uuidgen'
      SETTINGS_DIRECTORY      = '/etc/suseConnect'
      ZYPPER_CREDENTIALS_DIR  = '/etc/zypp/credentials.d'
      CREDENTIALS_NAME        = 'NCCcredentials'
      NCC_CREDENTIALS_FILE    = File.join(ZYPPER_CREDENTIALS_DIR, CREDENTIALS_NAME)

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

        # returns username and password from NCC_CREDENTIALS_FILE
        #
        # == Returns:
        # tuple of username and password or nil for both values
        #
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
            # TODO: part of logging system
            # Logger.info "NCC credentials file not found at: #{NCC_CREDENTIALS_FILE}"
            nil
          end
        end

        # detect if this system is registered against SCC
        # == Returns:
        #
        def registered?
          return false unless credentials
          username = credentials.first
          username && username.include?( 'SCC_' )
        end

        def add_service(service)

          raise ArgumentError, 'only Service accepted' unless service.is_a? Service

          service.sources.each do |source_name, source_url|

            Zypper.remove_service(source_name)
            Zypper.add_service(source_name, source_url)

            service.enabled.each do |repo_name|
              Zypper.enable_service_repository(source_name, repo_name)
            end

            Zypper.write_source_credentials(source_name)

            service.norefresh.each do |repo_name|
              Zypper.disable_repository_autorefresh(source_name, repo_name)
            end

          end

          Zypper.refresh

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
