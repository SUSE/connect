require 'rexml/document'
require 'shellwords'
require 'fileutils'
require 'suse/connect/rexml_refinement'
require 'suse/toolkit/system_calls'

module SUSE
  module Connect
    # Implements zypper interaction
    module Zypper
      OEM_PATH  = '/var/lib/suseRegister/OEM'

      class << self
        include RexmlRefinement
        include SUSE::Toolkit::SystemCalls

        ##
        # Returns an array of all installed products, in which every product is
        # presented as a hash.
        def installed_products
          zypper_out = call('--no-refresh --xmlout --non-interactive products -i', false)
          xml_doc = REXML::Document.new(zypper_out, compress_whitespace: [])
          ary_of_products_hashes = xml_doc.root.elements['product-list'].elements.map(&:to_hash)
          ary_of_products_hashes.map {|hash| Product.new(hash) }
        end

        def base_product
          base = installed_products.find(&:isbase)
          base || raise(CannotDetectBaseProduct)
        end

        def distro_target
          call('targetos', false)
        end

        def enable_repository(name)
          call("--non-interactive modifyrepo -e #{name}")
        end

        def disable_repository(name)
          call("--non-interactive modifyrepo -d #{name}")
        end

        # Returns an array of hashes of all available repositories
        def repositories
          zypper_out = call('--xmlout --non-interactive repos -d', false)
          xml_doc = REXML::Document.new(zypper_out, compress_whitespace: [])
          xml_doc.elements.each('stream/repo-list/repo'){}.map{|r| r.to_hash.merge!(url: r.elements['url'].text) }
        end

        # @param service_url [String] url to appropriate repomd.xml to be fed to zypper
        # @param service_name [String] Alias-mnemonic with which zypper should add this service
        # @return [TrueClass]
        #
        # @todo TODO: introduce Product class
        def add_service(service_url, service_name)
          service = "#{Shellwords.escape(service_url)} '#{Shellwords.escape(service_name)}'"
          call("--non-interactive addservice -t ris #{service}")
          call("--non-interactive modifyservice -r #{Shellwords.escape(service_url)}")
        end

        # @param service_name [String] Alias-mnemonic with which zypper should remove this service
        def remove_service(service_name)
          call("--non-interactive removeservice '#{Shellwords.escape(service_name)}'")
          remove_service_credentials(service_name)
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

        # @param service_name [String] Alias-mnemonic with which service credentials file should be removed
        def remove_service_credentials(service_name)
          service_credentials_file = File.join(SUSE::Connect::Credentials::DEFAULT_CREDENTIALS_DIR, service_name)

          if File.exist?(service_credentials_file)
            File.delete service_credentials_file
          end
        end

        ##
        # Returns an array of hashes of all installed services
        def services
          zypper_out = call('--xmlout --non-interactive services -d', false)
          xml_doc = REXML::Document.new(zypper_out, compress_whitespace: [])
          xml_doc.elements.each('stream/service-list/service') {}.map(&:to_hash)
        end

        def refresh
          call('--non-interactive refresh')
        end

        def refresh_services
          call('--non-interactive refresh-services -r')
        end

        def write_service_credentials(service_name)
          login = System.credentials.username
          password = System.credentials.password
          credentials = Credentials.new(login, password, service_name)
          credentials.write
        end

        def write_base_credentials(login, password)
          credentials = Credentials.new(login, password, Credentials.system_credentials_file)
          credentials.write
        end

        private

        def root_arg
          "--root '#{SUSE::Connect::System.filesystem_root}' " if SUSE::Connect::System.filesystem_root
        end

        # NOTE: Always calls zypper in a silent mode unless quite=false option is set
        def call(args, quiet = true)
          cmd  = "zypper #{root_arg}#{args}"
          execute(cmd, quiet)
        end
      end
    end
  end
end
