require 'rexml/document'
require 'shellwords'
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
          zypper_out = call_with_output('zypper --no-refresh --quiet --xmlout --non-interactive products -i')
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
          call_with_output('zypper targetos')
        end

        def add_service(service_name, service_url)
          call("zypper --quiet --non-interactive addservice -t ris #{Shellwords.escape(service_url)} '#{Shellwords.escape(service_name)}'")
        end

        def enable_autorefresh_service(service_name)
          call("zypper --quiet --non-interactive modifyservice -r #{Shellwords.escape(service_name)}")
        end

        def remove_service(service_name)
          call("zypper --quiet --non-interactive removeservice '#{Shellwords.escape(service_name)}'")
        end

        def refresh
          call('zypper refresh')
        end

        def refresh_services
          call('zypper refresh-services -r')
        end

        def enable_service_repository(service_name, repository)
          call("zypper --quiet modifyservice --ar-to-enable '#{Shellwords.escape(service_name)}:#{Shellwords.escape(repository)}' " +
            "'#{Shellwords.escape(service_name)}'")
        end

        def disable_repository_autorefresh(service_name, repository)
          call("zypper --quiet modifyrepo --no-refresh '#{Shellwords.escape(service_name)}:#{Shellwords.escape(repository)}'")
        end

        def write_service_credentials(service_name)
          login, password = System.credentials.username, System.credentials.password
          credentials = Credentials.new(login, password, service_name)
          credentials.write
        end

        def write_base_credentials(login, password)
          credentials = Credentials.new(login, password, Credentials::GLOBAL_CREDENTIALS_FILE)
          credentials.write
        end

        private

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
