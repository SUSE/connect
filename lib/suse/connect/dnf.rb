require 'rexml/document'
require 'shellwords'
require 'fileutils'
require 'json'
require 'suse/connect/rexml_refinement'
require 'suse/toolkit/system_calls'
module SUSE
  module Connect

    # Implements dnf interaction
    module Dnf
      OS_RELEASE_FILE = '/etc/os-release'.freeze
      HELPER_SCRIPT = File.join(File.dirname(__FILE__), 'dnf', 'dnf_helper.py')

      class << self
        include RexmlRefinement
        include SUSE::Toolkit::SystemCalls

        ##
        # Returns an array of all installed products, in which every product is
        # presented as a hash.
        def installed_products
          return [] unless File.exist?(OS_RELEASE_FILE)

          System.read_file(OS_RELEASE_FILE).each_line do |line|
            matches = line.chomp.scan(/REDHAT_BUGZILLA_PRODUCT=\"Red Hat Enterprise Linux (.+)\"/)
            return [Product.new(identifier: 'RES', version: matches[0][0], arch: 'unknown')] unless matches.empty?
          end
          []
        end

        def base_product
          base = installed_products.first
          base || raise(CannotDetectBaseProduct)
        end

        def enable_repository(name)
          call("config-manager --set-enabled #{Shellwords.escape(name)}")
        end

        def disable_repository(name)
          call("config-manager --set-disabled #{Shellwords.escape(name)}")
        end

        # Returns an array of hashes of all available repositories
        def repositories
          helper_out = execute("python3 #{HELPER_SCRIPT} --repos", true, [0])
          JSON.parse(helper_out, symbolize_names: true)
        end

        def root_arg
          "--installroot '#{SUSE::Connect::System.filesystem_root}' " if SUSE::Connect::System.filesystem_root
        end

        # NOTE: Always calls zypper in a silent mode unless quiet=false option is set
        def call(args, quiet = true, valid_exit_codes = [0])
          cmd = "dnf #{root_arg}#{args}"
          execute(cmd, quiet, valid_exit_codes)
        end
      end
    end
  end
end
