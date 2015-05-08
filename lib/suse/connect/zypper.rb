require 'rexml/document'
require 'shellwords'
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
          zypper_out = call('--xmlout --non-interactive products -i', false)
          xml_doc = REXML::Document.new(zypper_out, :compress_whitespace => [])
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

        # @param service_url [String] url to appropriate repomd.xml to be fed to zypper
        # @param service_name [String] Alias-mnemonic with which zypper should add this service
        # @return [TrueClass]
        #
        # @todo TODO: introduce Product class
        def add_service(service_url, service_name)
          service = "#{Shellwords.escape(service_url)} '#{Shellwords.escape(service_name)}'"
          call("--non-interactive addservice -t ris #{service}")
        end

        # @param service_name [String] Alias-mnemonic with which zypper should add this service
        def remove_service(service_name)
          call("--non-interactive removeservice '#{Shellwords.escape(service_name)}'")
        end

        ##
        # Remove all installed services
        def remove_all_services
          services.map do |service_name|
            remove_service(service_name)
          end
        end

        ##
        # Returns an array of all installed service names
        def services
          output = call('services', false)
          lines = output.split("\n").drop(2)
          lines.map do |line|
            line.split('|')[2].strip
          end
        end

        def refresh
          call('--non-interactive refresh')
        end

        def refresh_services
          call('--non-interactive refresh-services -r')
        end

        def write_service_credentials(service_name)
          login, password = System.credentials.username, System.credentials.password
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
