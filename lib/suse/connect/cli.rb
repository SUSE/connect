require 'optparse'
require 'suse/connect'

module SUSE
  module Connect
    # Command line interface for interacting with SUSEConnect
    class Cli  # rubocop:disable ClassLength
      include Logger

      attr_reader :options

      def initialize(argv)
        @options = {}
        @argv = argv
        extract_options
        extract_environment
      end

      def execute! # rubocop:disable MethodLength, CyclomaticComplexity
        # check for parameter dependencies
        if @options[:status]
          Status.print_product_statuses(:json)
        elsif @options[:status_text]
          Status.print_product_statuses(:text)
        else
          if @options[:instance_data_file] && !@options[:url]
            log.error 'Please use --instance-data only in combination with --url pointing to your SMT server'
            exit(1)
          elsif @options[:url].nil? && @options[:token].nil?
            log.error 'Please set the token parameter to register against SCC, or the url parameter to register against SMT'
            exit(1)
          elsif @options[:token] && @options[:instance_data_file]
            log.error 'Please use either --token or --instance-data'
            exit(1)
          else
            Client.new(@options).register!
          end

        end

      rescue Errno::ECONNREFUSED
        log.fatal "Error: Connection refused by server #{@options[:url] || 'https://scc.suse.com'}"
        exit 64
      rescue Errno::EACCES => e
        log.fatal "Error: Access error - #{e.message}"
        exit 65
      rescue JSON::ParserError
        log.fatal 'Error: Cannot parse response from server'
        exit 66
      rescue ApiError => e
        if e.code == 401
          log.fatal "Existing SCC credentials were not recognised, probably because the registered system was unregistered or deleted. Check #{@options[:url] || 'https://scc.suse.com'} whether your system appears there. If it does not, remove /etc/SUSEConnect and re-register this system."
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

        @opts.on('--instance-data  [path to file]', 'Path to the XML file holding the public key and instance data',
                 '  for cloud registration with SMT') do |opt|
          check_if_param(opt, 'Please provide the path to your instance data file')
          @options[:instance_data_file] = opt
        end

        @opts.on('-e', '--email <email>', 'email address for product registration') do |opt|
          check_if_param(opt, 'Please provide an email address')
          @options[:email] = opt
        end

        @opts.on('--url [URL]', 'URL of registration server (e.g. https://scc.suse.com).') do |opt|
          check_if_param(opt, 'Please provide registration server URL')
          @options[:url] = opt
        end

        @opts.on('-s', '--status', 'get current system registration status in json format') do |opt|
          @options[:status] = true
        end

        @opts.on('--status-text', 'get current system registration status in text format') do |opt|
          @options[:status_text] = true
        end

        @opts.on('--write-config', 'write options to config file at /etc/SUSEConnect') do |opt|
          @options[:write_config] = true
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
        log.debug("cmd options: '#{@options}'")

      end

      def extract_environment
        @options[:language] = ENV['LANG'] if ENV['LANG']
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
