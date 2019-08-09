require 'rexml/document'
require 'shellwords'
require 'fileutils'
require 'suse/connect/rexml_refinement'
require 'suse/toolkit/system_calls'

# rubocop:disable Metrics/ModuleLength
module SUSE
  module Connect

    # Implements zypper interaction
    module Zypper

      # Contains zypper exit codes, taken from zypper 1.12.37 manpage
      module ExitCode
        OK = 0

        # Single-digit codes denote errors
        module Error
          BUG          = 1 # Unexpected situation occurred, probably caused by a bug
          SYNTAX       = 2 # zypper was invoked with an invalid command or option, or a bad syntax
          INVALID_ARGS = 3 # Some of provided arguments were invalid. E.g. an invalid URI was provided to the addrepo command
          ZYPP         = 4 # A problem is reported by ZYPP library
          PRIVILEGES   = 5 # User invoking zypper has insufficient privileges for specified operation
          NO_REPOS     = 6 # No repositories are defined
          ZYPP_LOCKED  = 7 # The ZYPP library is locked, e.g. packagekit is running
          COMMIT       = 8 # An error occurred during installation or removal of packages. You may run zypper verify to repair any dependency problems
        end

        # Codes from 100 and above denote additional information passing
        module Info
          UPDATE_NEEDED     = 100 # Returned by the patch-check command if there are patches available for installation
          SEC_UPDATE_NEEDED = 101 # Returned by the patch-check command if there are security patches available for installation
          REBOOT_NEEDED     = 102 # Returned after a successful installation of a patch which requires reboot of computer
          RESTART_NEEDED    = 103 # Returned after a successful installation of a patch which requires restart of the package manager itself
          CAP_NOT_FOUND     = 104 # install or remove command encountered arguments matching no of the available package names or capabilities
          ON_SIGNAL         = 105 # Returned upon exiting after receiving a SIGINT or SIGTERM
          REPOS_SKIPPED     = 106 # Some repository had to be disabled temporarily because it failed to refresh
        end
      end

      OEM_PATH = '/var/lib/suseRegister/OEM'

      class << self
        include RexmlRefinement
        include SUSE::Toolkit::SystemCalls

        ##
        # Returns an array of all installed products, in which every product is
        # presented as a hash.
        def installed_products
          zypper_out = call('--disable-repositories --xmlout --non-interactive products -i', false)
          xml_doc = REXML::Document.new(zypper_out, compress_whitespace: [])
          ary_of_products_hashes = xml_doc.root.elements['product-list'].elements.map(&:to_hash)
          ary_of_products_hashes.map { |hash| Product.new(hash) }
        end

        def base_product
          base = installed_products.find(&:isbase)
          base || raise(CannotDetectBaseProduct)
        end

        def distro_target
          call('targetos', false)
        end

        def enable_repository(name)
          call("--non-interactive modifyrepo -e #{Shellwords.escape(name)}")
        end

        def disable_repository(name)
          call("--non-interactive modifyrepo -d #{Shellwords.escape(name)}")
        end

        def refresh
          call('--non-interactive refresh')
        end

        # Returns an array of hashes of all available repositories
        def repositories
          # Don't fail when zypper exits with 6 (no repositories)
          zypper_out = call('--xmlout --non-interactive repos -d', false, [Zypper::ExitCode::OK, Zypper::ExitCode::Error::NO_REPOS])
          xml_doc = REXML::Document.new(zypper_out, compress_whitespace: [])
          xml_doc.elements.to_a('stream/repo-list/repo').map { |r| r.to_hash.merge!(url: r.elements['url'].text) }
        end

        # @param service_url [String] url to appropriate repoindex.xml to be fed to zypper
        # @param service_name [String] Alias-mnemonic with which zypper should add this service
        # @return [TrueClass]
        #
        # @see https://doc.opensuse.org/projects/libzypp/HEAD/zypp-services.html#services-remote ZYpp Services Documentation
        # @todo TODO: introduce Product class
        def add_service(service_url, service_name, refresh_zypper_service = true)
          # INFO: Remove old service which could be modified by a customer
          remove_service(service_name)
          call("--non-interactive addservice -t ris #{Shellwords.escape(service_url)} '#{Shellwords.escape(service_name)}'")
          enable_service_autorefresh(service_name)
          write_service_credentials(service_name)

          refresh_service(service_name) if refresh_zypper_service
        end

        # @param service_name [String] Alias-mnemonic with which zypper should remove this service
        def remove_service(service_name)
          call("--non-interactive removeservice '#{Shellwords.escape(service_name)}'")
          remove_service_credentials(service_name)
        end

        # @param service_name [String] Alias-mnemonic with which zypper should refresh a service
        def refresh_service(service_name)
          call("--non-interactive refs #{Shellwords.escape(service_name)}")
        end

        def refresh_all_services
          call('--non-interactive refs')
        end

        # @param product identifier [String]
        # Returns an array of hashes of all solvable products
        def find_products(identifier)
          # Don't fail when zypper exits with 104 (no product found) or 6 (no repositories)
          zypper_out = call("--xmlout --no-refresh --non-interactive search --match-exact -s -t product #{Shellwords.escape(identifier)}", false,
                            [Zypper::ExitCode::OK, Zypper::ExitCode::Info::CAP_NOT_FOUND, Zypper::ExitCode::Error::NO_REPOS])
          xml_doc = REXML::Document.new(zypper_out, compress_whitespace: [])
          xml_doc.elements.to_a('stream/search-result/solvable-list/solvable').map(&:to_hash)
        end

        ##
        # Remove all installed SUSE services
        def remove_all_suse_services
          services.each do |service|
            if service[:url].include?(Config.new.url)
              remove_service(service[:name])
            end
          end
        end

        # @param service_name [String] Alias-mnemonic with which zypper should enable service autorefresh
        def enable_service_autorefresh(service_name)
          call("--non-interactive modifyservice -r #{Shellwords.escape(service_name)}")
        end

        def refresh_services
          call('--non-interactive refresh-services -r')
        end

        ##
        # Returns an array of hashes of all installed services
        def services
          # Don't fail when zypper exits with 6 (no repositories)
          zypper_out = call('--xmlout --non-interactive services -d', false, [Zypper::ExitCode::OK, Zypper::ExitCode::Error::NO_REPOS])
          xml_doc = REXML::Document.new(zypper_out, compress_whitespace: [])
          xml_doc.elements.to_a('stream/service-list/service').map(&:to_hash)
        end

        def install_release_package(identifier)
          return unless identifier
          _, _, status = execute_raw("rpm -q #{identifier}-release")
          call("--no-refresh --non-interactive install --no-recommends --auto-agree-with-product-licenses -t product #{identifier}") unless (status == 0)
        end

        def remove_release_package(identifier)
          call("--no-refresh --non-interactive remove -t product #{identifier}") if identifier
        end

        # rubocop:disable AccessorMethodName
        def set_release_version(version)
          call("--non-interactive --releasever #{version} ref -f")
        end

        def write_service_credentials(service_name)
          login = System.credentials.username
          password = System.credentials.password
          credentials = Credentials.new(login, password, service_name)
          credentials.write
        end

        # @param service_name [String] Alias-mnemonic with which service credentials file should be removed
        def remove_service_credentials(service_name)
          service_credentials_file = File.join(SUSE::Connect::Credentials::DEFAULT_CREDENTIALS_DIR, service_name)

          if File.file?(service_credentials_file)
            File.delete service_credentials_file
          end
        end

        def write_base_credentials(login, password)
          credentials = Credentials.new(login, password, Credentials.system_credentials_file)
          credentials.write
        end

        private

        def root_arg
          "--root '#{SUSE::Connect::System.filesystem_root}' " if SUSE::Connect::System.filesystem_root
        end

        # NOTE: Always calls zypper in a silent mode unless quiet=false option is set
        def call(args, quiet = true, valid_exit_codes = [0])
          cmd = "zypper #{root_arg}#{args}"
          execute(cmd, quiet, valid_exit_codes)
        end
      end
    end
  end
end
