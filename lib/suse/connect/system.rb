module SUSE
  module Connect
    # System class allowing to interact with underlying system
    class System

      class << self

        attr_accessor :filesystem_root

        def hwinfo
          info = {
            :cpu_type => `uname -p`,
            :cpu_count => `grep "processor" /proc/cpuinfo | wc -l`,
            :platform_type => `uname -i`,
            :hostname => `hostname`
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
          if File.exist?(Credentials.system_credentials_file)
            Credentials.read(Credentials.system_credentials_file)
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
          File.delete Credentials.system_credentials_file if registered?
        end

        def add_service(service)

          raise ArgumentError, 'only Service accepted' unless service.is_a? Service

          service.sources.each do |source|

            Zypper.remove_service(source.name)
            Zypper.add_service(source.name, source.url)
            Zypper.enable_autorefresh_service(source.name)

            service.enabled.each do |repo_name|
              Zypper.enable_service_repository(source.name, repo_name)
            end

            Zypper.write_service_credentials(source.name)

            service.norefresh.each do |repo_name|
              Zypper.disable_repository_autorefresh(source.name, repo_name)
            end

          end

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
