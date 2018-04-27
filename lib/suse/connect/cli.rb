require 'optparse'
require 'suse/connect'

module SUSE
  module Connect
    # Command line interface for interacting with SUSEConnect
    class Cli # rubocop:disable ClassLength
      include Logger

      attr_reader :config, :options

      def initialize(argv)
        @options = {}
        @argv = argv
        extract_options
        @config = Config.new.merge!(@options)
      end

      def execute! # rubocop:disable MethodLength, CyclomaticComplexity, PerceivedComplexity, AbcSize
        # check for parameter dependencies
        if @config.status
          status.print_product_statuses(:json)
        elsif @config.status_text
          status.print_product_statuses(:text)
        elsif @config.deregister
          Client.new(@config).deregister!
        elsif @config.cleanup
          System.cleanup!
        elsif @config.rollback
          Migration.rollback
        elsif @config.list_extensions
          if status.activated_base_product?
            status.print_extensions_list
          else
            log.error 'To list extensions, you must first register the base product, using: SUSEConnect -r <registration code>'
            exit(1)
          end
        else
          if @config.instance_data_file && @config.url_default?
            log.error 'Please use --instance-data only in combination with --url pointing to your SMT server'
            exit(1)
          elsif @config.token && @config.instance_data_file
            log.error 'Please use either --regcode or --instance-data'
            exit(1)
          elsif @config.url_default? && !@config.token && !status.activated_base_product?
            log.error 'Please register your system using the --regcode parameter, or provide the --url parameter to register against SMT.'
            exit(1)
          else
            Client.new(@config).register!
          end
        end

        @config.write! if @config.write_config
      rescue Errno::ECONNREFUSED
        log.fatal "Error: Connection refused by server #{@config.url}"
        exit 64
      rescue Errno::EACCES => e
        log.fatal "Error: Access error - #{e.message}"
        exit 65
      rescue JSON::ParserError
        log.fatal complain_if_broken_smt || 'Error: Cannot parse response from server'
        exit 66
      rescue ApiError => e
        if e.code == 401 && System.credentials?
          log.fatal 'Error: Invalid system credentials, probably because the registered system was deleted in SUSE Customer Center.' \
          " Check #{@options[:url] || 'https://scc.suse.com'} whether your system appears there." \
          ' If it does not, please call SUSEConnect --cleanup and re-register this system.'
        else
          log.fatal complain_if_broken_smt || "Error: Registration server returned '#{e.message}' (#{e.code})"
        end
        exit 67
      rescue FileError => e
        log.fatal "FileError: '#{e.message}'"
        exit 68
      rescue ZypperError => e
        # Zypper errors are in the range 1-7 and 100-105 (which connect will not cause)
        log.fatal "Error: zypper returned (#{e.exitstatus}) with '#{e.output}'"
        exit e.exitstatus
      rescue SystemNotRegisteredError
        log.fatal 'Deregistration failed. Check if the system has been '\
                  'registered using the --status-text option or use the '\
                  '--regcode parameter to register it.'
        exit 69
      rescue BaseProductDeactivationError
        log.fatal 'Can not deregister base product. Use SUSEConnect -d to deactivate the whole system.'
        exit 70
      end

      private

      def complain_if_broken_smt
        unless @config.url_default? || Client.new(@config).api.up_to_date?
          return "Your Registration Proxy server doesn't support this function. Please update it and try again."
        end
      end

      def extract_options # rubocop:disable MethodLength
        @opts = OptionParser.new

        @opts.separator 'Register SUSE Linux Enterprise installations with the SUSE Customer Center.'
        @opts.separator 'Registration allows access to software repositories (including updates)'
        @opts.separator 'and allows online management of subscriptions and organizations.'
        @opts.separator ''
        @opts.separator 'Manage subscriptions at https://scc.suse.com'
        @opts.separator ''
        @opts.on('-p', '--product [PRODUCT]',
                 'Specify a product for activation/deactivation. Only',
                 'one product can be processed at a time. Defaults to',
                 'the base SUSE Linux Enterprise product on this ',
                 'system. Product identifiers can be obtained',
                 'with `--list-extensions`.',
                 'Format: <name>/<version>/<architecture>') do |opt|
          check_if_param(opt, 'Please provide a product identifier')
          # rubocop:disable RegexpLiteral
          check_if_param((opt =~ /\S+\/\S+\/\S+/), 'Please provide the product identifier in this format: ' \
            '<internal name>/<version>/<architecture>. You can find these values by calling: ' \
            '\'SUSEConnect --list-extensions\'. ')
          identifier, version, arch = opt.split('/')
          @options[:product] = Remote::Product.new(identifier: identifier, version: version, arch: arch)
        end

        @opts.on('-r', '--regcode [REGCODE]',
                 'Subscription registration code for the product to',
                 'be registered.',
                 'Relates that product to the specified subscription,',
                 'and enables software repositories for that product.') do |opt|
          @options[:token] = opt
        end

        @opts.on('-d', '--de-register',
                 'De-registers the system and base product, or in',
                 'conjunction with --product, a single extension, and',
                 'removes all its services installed by SUSEConnect.',
                 'After de-registration the system no longer consumes',
                 'a subscription slot in SCC.') do |_opt|
          @options[:deregister] = true
        end

        @opts.on('--instance-data  [path to file]', 'Path to the XML file holding the public key and',
                 'instance data for cloud registration with SMT.') do |opt|
          check_if_param(opt, 'Please provide the path to your instance data file')
          @options[:instance_data_file] = opt
        end

        @opts.on('-e', '--email <email>', 'Email address for product registration.') do |opt|
          check_if_param(opt, 'Please provide an email address')
          @options[:email] = opt
        end

        @opts.on('--url [URL]', 'URL of registration server',
                 '(e.g. https://scc.suse.com).',
                 'Implies --write-config so that subsequent',
                 'invocations use the same registration server.') do |opt|
          check_if_param(opt, 'Please provide registration server URL')
          @options[:url] = opt
          @options[:write_config] = true
        end

        @opts.on('--namespace [NAMESPACE]', 'Namespace option for use with SMT staging',
                 'environments.') do |opt|
          check_if_param(opt, 'Please provide a namespace')
          @options[:namespace] = opt
          @options[:write_config] = true
        end

        @opts.on('-s', '--status', 'Get current system registration status in json',
                 'format.') do |_opt|
          @options[:status] = true
        end

        @opts.on('--status-text', 'Get current system registration status in text',
                 'format.') do |_opt|
          @options[:status_text] = true
        end

        @opts.on('--list-extensions', 'List all extensions and modules available for',
                 'installation on this system.') do |_opt|
          @options[:list_extensions] = true
        end

        @opts.on('--write-config', 'Write options to config file at /etc/SUSEConnect.') do |_opt|
          @options[:write_config] = true
        end

        @opts.on('--cleanup', 'Remove old system credentials and all zypper',
                 'services installed by SUSEConnect.') do |_opt|
          @options[:cleanup] = true
        end

        @opts.on('--rollback', 'Revert the registration state in case of a failed',
                 'migration.') do |_opt|
          @options[:rollback] = true
        end

        @opts.separator ''
        @opts.separator 'Common options:'

        @opts.on('--root [PATH]', 'Path to the root folder, uses the same parameter',
                 'for zypper.') do |opt|
          check_if_param(opt, 'Please provide path parameter')
          @options[:filesystem_root] = opt
          SUSE::Connect::System.filesystem_root = opt
        end

        @opts.on('--version', 'Print program version.') do
          puts VERSION
          exit 0
        end

        @opts.on('--debug', 'Provide debug output.') do |opt|
          @options[:debug] = opt
          SUSE::Connect::GlobalLogger.instance.log.level = ::Logger::DEBUG if opt
        end

        @opts.on_tail('-h', '--help', 'Show this message.') do
          puts @opts
          exit 0
        end

        @opts.set_summary_width(24)
        @opts.parse(@argv)
        @options[:language] = ENV['LANG'] if ENV['LANG']
        log.debug("cmd options: '#{@options}'")
      end

      def check_if_param(opt, message)
        unless opt
          log.error message
          exit 1
        end
      end

      def status
        @status ||= Status.new(@config)
      end
    end
  end
end
