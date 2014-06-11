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
          zypper_out = call_zypper(:with_output, '--no-refresh --quiet ' \
                                                 '--xmlout --non-interactive products -i')
          xml_doc = REXML::Document.new(zypper_out, :compress_whitespace => [])
          ary_of_products_hashes = xml_doc.root.elements['product-list'].elements.map(&:to_hash)
          ary_of_products_hashes.map {|hash| Product.new(hash) }
        end

        def base_product
          base = installed_products.select {|product| product.isbase }.first
          if base
            base
          else
            raise CannotDetectBaseProduct
          end
        end

        def distro_target
          call_zypper(:with_output, 'targetos')
        end

        # @param service_url [String] url to appropriate repomd.xml to be fed to zypper
        # @param service_name [String] Alias-mnemonic with which zypper should add this service
        # @return [TrueClass]
        #
        # @todo TODO: introduce Product class
        def add_service(service_url, service_name)
          call_zypper(:silently, "--quiet --non-interactive addservice -t ris " \
               "#{Shellwords.escape(service_url)} '#{Shellwords.escape(service_name)}'")
        end

        def remove_service(service_name)
          call_zypper(:silently, "--quiet --non-interactive removeservice '#{Shellwords.escape(service_name)}'")
        end

        def refresh
          call_zypper(:silently, 'refresh')
        end

        def refresh_services
          call_zypper(:silently, 'refresh-services -r')
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

        def call_zypper(silent, args)
          cmd  = "zypper #{root_arg}#{args}"
          zypper_out = nil
          if silent == :with_output
            zypper_out = call_with_output(cmd)
          else
            call(cmd)
          end
          zypper_out
        end

      end
    end
  end
end
