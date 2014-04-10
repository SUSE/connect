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

        # returns username and password from SCC_CREDENTIALS_FILE
        #
        # == Returns:
        # Credentials object or nil
        #
        def credentials
          if File.exist?(Credentials::GLOBAL_CREDENTIALS_FILE)
            Credentials::read(Credentials::GLOBAL_CREDENTIALS_FILE)
          else
            nil
          end
        end

        # detect if this system is registered against SCC
        # == Returns:
        #
        def registered?
          creds = credentials
          creds && creds.username && creds.username.include?('SCC_')
        end

        def remove_credentials
          File.delete Credentials::GLOBAL_CREDENTIALS_FILE if registered?
        end

        def add_service(service)

          raise ArgumentError, 'only Service accepted' unless service.is_a? Service

          service.sources.each do |source|

            Zypper.remove_service(source.name)
            Zypper.add_service(source.name, source.url)
            # TODO: cover
            Zypper.enable_autorefresh_service(source.name)

            # TODO: ensure zypper reads and respects repoindex flags
            service.enabled.each do |repo_name|
              Zypper.enable_service_repository(source.name, repo_name)
            end

            Zypper.write_service_credentials(source.name)

            # TODO: ensure zypper reads and respects repoindex flags
            service.norefresh.each do |repo_name|
              Zypper.disable_repository_autorefresh(source.name, repo_name)
            end

          end
          # TODO: cover
          Zypper.refresh_services
          service
        end

        def hostname
          hostname = Socket.gethostname
          if hostname && hostname != '(none)'
            hostname
          else
            Socket.ip_address_list.find {|intf| intf.ipv4_private? }.ip_address
          end
        end

      end
    end
  end
end
