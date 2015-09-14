require 'optparse'
require 'suse/connect'

module SUSE
  module Connect
    # Command line interface for interacting with SUSEConnect
    class Cli  # rubocop:disable ClassLength
      include Logger

      attr_reader :config, :options

      def initialize(argv)
        @options = {}
        @argv = argv
        extract_options
        @config = Config.new.merge!(@options)
      end

      def execute! # rubocop:disable MethodLength, CyclomaticComplexity
        # check for parameter dependencies
        if @config.status
          Status.new(@config).print_product_statuses(:json)
        elsif @config.status_text
          Status.new(@config).print_product_statuses(:text)
        elsif @config.deregister
          Client.new(@config).deregister!
        elsif @config.cleanup
          System.cleanup!
        else
          if @config.instance_data_file && @config.url_default?
            log.error 'Please use --instance-data only in combination with --url pointing to your SMT server'
            exit(1)
          elsif @config.token.nil? && @config.url_default?
            log.error 'Please set the regcode parameter to register against SCC, or the url parameter to register against SMT'
            exit(1)
          elsif @config.token && @config.instance_data_file
            log.error 'Please use either --token or --instance-data'
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
        log.fatal 'Error: Cannot parse response from server'
        exit 66
      rescue ApiError => e
        if e.code == 401 && System.credentials?
          log.fatal 'Error: Invalid system credentials, probably because the registered system was deleted in SUSE Customer Center.' \
          " Check #{@options[:url] || 'https://scc.suse.com'} whether your system appears there." \
          ' If it does not, please call SUSEConnect --cleanup and re-register this system.'
        else
          log.fatal "Error: SCC returned '#{e.message}' (#{e.code})"
        end
        exit 67
      rescue FileError => e
        log.fatal "FileError: '#{e.message}'"
        exit 68
      rescue ZypperError => e
        # Zypper errors are in the range 1-7 and 100-105 (which connect will not cause)
        log.fatal "Error: zypper returned (#{e.exitstatus}) with '#{e.output}'"
        exit e.exitstatus
      end

      private

      def extract_options # rubocop:disable MethodLength
        @opts = OptionParser.new

        @opts.separator 'Register SUSE Linux Enterprise installations with the SUSE Customer Center.'
        @opts.separator 'Registration allows access to software repositories including updates,'
        @opts.separator 'and allows online management of subscriptions and organizations'
        @opts.separator ''
        @opts.separator 'Manage subscriptions at https://scc.suse.com'
        @opts.separator ''
        @opts.on('-p', '--product [PRODUCT]', 'Activate PRODUCT. Defaults to the base SUSE Linux',
                 '  Enterprise product on this system.',
                 '  Product identifiers can be obtained with \'zypper products\'',
                 '  Format: <internal name>/<version>/<architecture>') do |opt|
          check_if_param(opt, 'Please provide a product identifier')
          # rubocop:disable RegexpLiteral
          check_if_param((opt =~ /\S+\/\S+\/\S+/), 'Please provide the product identifier in this format: ' \
            '<internal name>/<version>/<architecture>. For installed products you can find these values by calling: ' \
            '\'zypper products\'. ')
          identifier, version, arch = opt.split('/')
          @options[:product] = Remote::Product.new(identifier: identifier, version: version, arch: arch)
        end

        @opts.on('-r', '--regcode [REGCODE]', 'Subscription registration code for the',
                 '  product to be registered.',
                 '  Relates that product to the specified subscription,',
                 '  and enables software repositories for that product') do |opt|
          check_if_param(opt, 'Please provide a registration code parameter')
          @options[:token] = opt
        end

        @opts.on('-d', '--de-register', 'De-registers a system in order to not consume a subscription slot in SCC anymore',
                 ' and removes all services installed by SUSEConnect') do |_opt|
          @options[:deregister] = true
        end

        @opts.on('--instance-data  [path to file]', 'Path to the XML file holding the public key and instance data',
                 '  for cloud registration with SMT') do |opt|
          check_if_param(opt, 'Please provide the path to your instance data file')
          @options[:instance_data_file] = opt
        end

        @opts.on('-e', '--email <email>', 'email address for product registration') do |opt|
          check_if_param(opt, 'Please provide an email address')
          @options[:email] = opt
        end

        @opts.on('--url [URL]', 'URL of registration server (e.g. https://scc.suse.com).',
                 '  Implies --write-config so that subsequent invocations use the same registration server.') do |opt|
          check_if_param(opt, 'Please provide registration server URL')
          @options[:url] = opt
          @options[:write_config] = true
        end

        @opts.on('--namespace [NAMESPACE]', 'namespace option for use with SMT staging environments') do |opt|
          check_if_param(opt, 'Please provide a namespace')
          @options[:namespace] = opt
        end

        @opts.on('-s', '--status', 'get current system registration status in json format') do |_opt|
          @options[:status] = true
        end

        @opts.on('--status-text', 'get current system registration status in text format') do |_opt|
          @options[:status_text] = true
        end

        @opts.on('--write-config', 'write options to config file at /etc/SUSEConnect') do |_opt|
          @options[:write_config] = true
        end

        @opts.on('--cleanup', 'remove old system credentials and all zypper services installed by SUSEConnect') do |_opt|
          @options[:cleanup] = true
        end

        @opts.separator ''
        @opts.separator 'Common options:'

        @opts.on('--root [PATH]', 'Path to the root folder, uses the same parameter for zypper.') do |opt|
          check_if_param(opt, 'Please provide path parameter')
          @options[:filesystem_root] = opt
          SUSE::Connect::System.filesystem_root = opt
        end

        @opts.on('--version', 'print program version') do
          puts VERSION
          exit
        end

        @opts.on('--debug', 'provide debug output') do |opt|
          @options[:debug] = opt
          SUSE::Connect::GlobalLogger.instance.log.level = ::Logger::DEBUG if opt
        end

        @opts.on_tail('-h', '--help', 'show this message') do
          puts @opts
          exit
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
    end
  end
end
