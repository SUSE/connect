module SUSE
  module Connect
    # System class allowing to interact with underlying system
    class System

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
              :hostname       => `hostname`
          }

          info.values.each(&:chomp!)
          dmidecode = `dmidecode`
          virt_zoo = ['vmware', 'virtual machine', 'qemu', 'domu']
          info[:virtualized] = (virt_zoo).any? {|ident| dmidecode.downcase.include? ident } if dmidecode
          info
        end

        # returns username and password from NCC_CREDENTIALS_FILE
        #
        # == Returns:
        # tuple of username and password or nil for both values
        #
        def credentials
          if File.exist?(CREDENTIALS_FILE)

            file = File.new(CREDENTIALS_FILE, 'r')

            begin
              lines = file.readlines.map(&:chomp)
              extract_credentials(lines)
            ensure
              file.close
            end

          else
            nil
          end
        end

        # detect if this system is registered against SCC
        # == Returns:
        #
        def registered?
          return false unless credentials
          username = credentials.first
          username && username.include?('SCC_')
        end

        def add_service(service)

          raise ArgumentError, 'only Service accepted' unless service.is_a? Service

          service.sources.each do |service_name, source_url|

            Zypper.remove_service(service_name)
            Zypper.add_service(service_name, source_url)
            # TODO: cover
            Zypper.enable_autorefresh_service(service_name)

            # TODO: ensure zypper reads and respects repoindex flags
            service.enabled.each do |repo_name|
              Zypper.enable_service_repository(service_name, repo_name)
            end

            Zypper.write_service_credentials(service_name)

            # TODO: ensure zypper reads and respects repoindex flags
            service.norefresh.each do |repo_name|
              Zypper.disable_repository_autorefresh(service_name, repo_name)
            end

          end
          # TODO: cover
          Zypper.refresh_services

        end

        def hostname
          hostname = Socket.gethostname
          if hostname && hostname != '(none)'
            hostname
          else
            Socket.ip_address_list.find {|intf| intf.ipv4_private? }.ip_address
          end
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
            username = divide_credential_tuple lines.select {|line| line =~ /^username=.*/ }.first
            password = divide_credential_tuple lines.select {|line| line =~ /^password=.*/ }.first
          rescue
            raise MalformedNccCredentialsFile, 'Cannot parse credentials file'
          end

          [username, password]
        end

        def divide_credential_tuple(tuple)
          tuple.split('=').last
        end

      end
    end
  end
end
