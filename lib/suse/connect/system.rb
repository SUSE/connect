module SUSE
  module Connect
    # System class allowing to interact with underlying system
    class System
      class << self
        attr_accessor :filesystem_root

        def prefix_path(path)
          filesystem_root ? File.join(filesystem_root, path) : path
        end

        # Returns an implementation of the package manager
        def package_manager
          @package_manager ||= if File.exist?(SUSE::Connect::System.prefix_path('/etc/redhat-release'))
                                 log.debug 'Detected Red Hat/CentOS/Fedora distribution'
                                 Dnf
                               else
                                 log.debug 'Detected SUSE/openSUSE distribution'
                                 Zypper
                               end
        end

        def hwinfo
          SUSE::Connect::HwInfo::Base.info
        end

        # returns username and password from SCC_CREDENTIALS_FILE
        #
        # == Returns:
        # Credentials object or nil
        #
        def credentials
          if File.exist?(Credentials.system_credentials_file)
            Credentials.read(Credentials.system_credentials_file)
          end
        end

        def credentials?
          !!credentials
        end

        def remove_credentials
          File.delete Credentials.system_credentials_file if credentials?
        end

        def cleanup!
          System.remove_credentials
          System.package_manager.remove_all_suse_services
        end

        def add_service(service)
          raise ArgumentError, 'only Remote::Service accepted' unless service.is_a? Remote::Service
          System.package_manager.add_service(service.url, service.name)
          service
        end

        def remove_service(service)
          raise ArgumentError, 'only Remote::Service accepted' unless service.is_a? Remote::Service
          System.package_manager.remove_service service.name
          service
        end

        def hostname
          hostname = Socket.gethostname
          if hostname && hostname != '(none)'
            hostname
          else
            # Fix for bnc#889869
            # Sending (and storing on our servers) the public IPs would be a privacy violation
            addr_info = Socket.ip_address_list.find(&:ipv4_private?)
            addr_info.ip_address if addr_info
          end
        end

        def read_file(path)
          file_path = SUSE::Connect::System.prefix_path(path)
          log.debug "Reading file from: #{file_path}"
          raise(FileError, 'File not found') unless File.readable?(file_path)
          File.read(file_path)
        end
      end
    end
  end
end
