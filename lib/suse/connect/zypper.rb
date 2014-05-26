require 'rexml/document'
require 'suse/connect/rexml_refinement'
require 'suse/toolkit/system_calls'

module SUSE
  module Connect
    # Implements zypper interaction
    class Zypper

      include RexmlRefinement

      OEM_PATH    = '/var/lib/suseRegister/OEM'

      class << self

        include SUSE::Toolkit::SystemCalls

        ##
        # Returns an array of all installed products, in which every product is
        # presented as a hash.
        def installed_products
          zypper_out = call_zypper(:with_output, '--no-refresh --quiet ' \
                                                 '--xmlout --non-interactive products -i')
          xml_doc = REXML::Document.new(zypper_out, :compress_whitespace => [])
          # Not unary because of https://bugs.ruby-lang.org/issues/9451
          xml_doc.root.elements['product-list'].elements.map(&:to_hash)
        end

        def base_product
          base = installed_products.select {|product| %w{1 true yes}.include?(product[:isbase]) }.first
          raise CannotDetectBaseProduct unless base
          base[:release_type] = lookup_product_release(base)
          base
        end

        def distro_target
          call_zypper(:with_output, 'targetos')
        end

        def add_service(service_name, service_url)
          call_zypper(:silently, "--quiet --non-interactive addservice -t ris " \
               "#{service_url} '#{service_name}'")
        end

        def enable_autorefresh_service(service_name)
          call_zypper(:silently, "--quiet --non-interactive modifyservice -r #{service_name}")
        end

        def remove_service(service_name)
          call_zypper(:silently, "--quiet --non-interactive removeservice '#{service_name}'")
        end

        def refresh
          call_zypper(:silently, 'refresh')
        end

        def refresh_services
          call_zypper(:silently, 'refresh-services -r')
        end

        def enable_service_repository(service_name, repository)
          call_zypper(:silently, "--quiet modifyservice --ar-to-enable " \
               "'#{service_name}:#{repository}' '#{service_name}'")
        end

        def disable_repository_autorefresh(service_name, repository)
          call_zypper(:silently, "--quiet modifyrepo --no-refresh '#{service_name}:#{repository}'")
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
          "--root '#{SUSE::Connect::System.filesystem_root}' " unless SUSE::Connect::System.filesystem_root.empty?
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

        def lookup_product_release(product)
          release  = product[:flavor]
          release  = product[:registerrelease] unless product[:registerrelease].empty?
          oem_file = File.join(OEM_PATH, product[:productline])
          if File.exist?(oem_file)
            line = File.readlines(oem_file).first
            release = line.chomp if line
          end
          release
        end

      end
    end
  end
end
