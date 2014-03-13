require 'rexml/document'
require 'suse/connect/rexml_refinement'
require 'suse/toolkit/system_calls'

module SUSE
  module Connect
    # Implements zypper interaction
    class Zypper

      include RexmlRefinement

      class << self

        include SUSE::Toolkit::SystemCalls

        ##
        # Returns an array of all installed products, in which every product is
        # presented as a hash.
        def installed_products
          zypper_out = `zypper --no-refresh --quiet --xmlout --non-interactive products -i`
          xml_doc = REXML::Document.new(zypper_out, :compress_whitespace => [])
          # Not unary because of https://bugs.ruby-lang.org/issues/9451
          xml_doc.root.elements['product-list'].elements.map(&:to_hash)
        end

        def base_product
          base = installed_products.select {|product| %w{1 true yes}.include?(product[:isbase]) }.first
          raise CannotDetectBaseProduct unless base
          base
        end

        def distro_target
            zypper_out = `zypper targetos`
            zypper_out.chomp
        end

        def add_service(service_name, service_url)
          zypper_args = "--quiet --non-interactive addservice -t ris #{service_url} '#{service_name}'"
          call(zypper_args)
        end

        def enable_autorefresh_service(service_name)
          zypper_args = "--quiet --non-interactive modifyservice -r #{service_name}"
          call(zypper_args)
        end

        def remove_service(service_name)
          zypper_args = "--quiet --non-interactive removeservice '#{service_name}'"
          call(zypper_args)
        end

        def refresh
          call('refresh')
        end

        def refresh_services
          call('refresh-services -r')
        end

        def enable_service_repository(service_name, repository)
          zypper_args = "--quiet modifyservice --ar-to-enable '#{service_name}:#{repository}' '#{service_name}'"
          call(zypper_args)
        end

        def disable_repository_autorefresh(service_name, repository)
          zypper_args = "--quiet modifyrepo --no-refresh '#{service_name}:#{repository}'"
          call(zypper_args)
        end

        # TODO: introduce Source class
        def write_source_credentials(source_name)
          login, password = System.credentials
          write_credentials_file(login, password, "#{source_name}_credentials")
        end

        def write_base_credentials(login, password)
          write_credentials_file(login, password, CREDENTIALS_NAME)
        end

        private

        def sccized_login(login)
          login.start_with?('SCC_') ? login : "SCC_#{login}"
        end

      end
    end
  end
end
