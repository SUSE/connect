require 'rexml/document'
require 'debugger'
require 'suse/connect/rexml_refinement'

module SUSE
  module Connect
    class Zypper

      using SUSE::Connect::RexmlRefinement

      class << self

        ##
        # Returns an array of all installed products, in which every product is presented as a hash.
        def installed_products
          zypper_out = `zypper --no-refresh --quiet --xmlout --non-interactive products -i`
          xml_doc = REXML::Document.new(zypper_out, :compress_whitespace => [])
          # Not unary because of https://bugs.ruby-lang.org/issues/9451
          xml_doc.root.elements['product-list'].elements.map{|x| x.to_hash }
        end

        def add_service(service_name, service_url)
          zypper_args = "--quiet --non-interactive addservice #{service_url} '#{service_name}'"
          call(zypper_args)
        end

        def remove_service(service_name)
          zypper_args = "--quiet --non-interactive removeservice '#{service_name}'"
          call(zypper_args)
        end

        def refresh
          call('refresh')
        end

        def enable_service_repository(service_name, repository)
          zypper_args = "--quiet modifyservice --ar-to-enable '#{service_name}:#{repository}' '#{service_name}'"
          call(zypper_args)
        end

        def disable_repository_autorefresh(service_name, repository)
          zypper_args = "--quiet modifyrepo --no-refresh '#{service_name}:#{repository}'"
          call(zypper_args)
        end

        private

          def call(args)
            command = "zypper #{args}"
            unless system(command)
              Logger.error "command `#{command}` failed"
            end
          end

      end
    end
  end
end
