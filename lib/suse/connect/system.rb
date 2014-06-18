require 'suse/toolkit/hwinfo'

module SUSE
  module Connect
    # System class allowing to interact with underlying system
    class System
      class << self
        include SUSE::Toolkit::Hwinfo

        attr_accessor :filesystem_root

        def hwinfo
          info = {
            hostname: hostname,
            cpus: cpus,
            sockets: sockets,
            hypervisor: hypervisor,
            arch: arch
          }
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
          !!(creds && creds.username && creds.username.include?('SCC_'))
        end

        def remove_credentials
          File.delete Credentials.system_credentials_file if registered?
        end

        def add_service(service)
          raise ArgumentError, 'only Remote::Service accepted' unless service.is_a? Remote::Service
          Zypper.remove_service(service.name)
          Zypper.add_service(service.url, service.name)
          Zypper.write_service_credentials(service.name)
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
