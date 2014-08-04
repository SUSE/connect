require 'suse/toolkit/hwinfo'

module SUSE
  module Connect
    # System class allowing to interact with underlying system
    class System
      class << self

        include SUSE::Toolkit::Hwinfo

        attr_accessor :filesystem_root

        def prefix_path(path)
          filesystem_root ? File.join(filesystem_root, path) : path
        end

        def hwinfo
          if x86?
            {
              hostname: hostname,
              cpus: cpus,
              sockets: sockets,
              hypervisor: hypervisor,
              arch: arch,
              uuid: uuid
            }
          else
            {
              hostname: hostname,
              arch: arch
            }
          end
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

        def credentials?
          !!credentials
        end

        # Checks if system activations includes base product
        def activated_base_product?
          credentials? && Status.activated_products.include?(Zypper.base_product)
        end

        def remove_credentials
          File.delete Credentials.system_credentials_file if credentials?
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
            # Fix for bnc#889869
            addr_info = Socket.ip_address_list.find {|intf| intf.ipv4_private? }
            addr_info.ip_address if addr_info
          end
        end

        def x86?
          %w{x86, x86_64}.include? arch
        end

      end
    end
  end
end
