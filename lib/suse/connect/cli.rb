require 'optparse'
require 'suse/connect'

module SUSE
  module Connect
    # Command line interface for interacting with SUSEConnect
    class Cli
      include Logger

      attr_reader :options

      def initialize(argv)
        @options = {}
        @argv = argv
        extract_options
      end

      def execute! # rubocop:disable MethodLength

        # TODO: proper mechanics to separate sub-commands
        if @options[:status]
          Client.new(@options).status.print
          exit(0)
        end

        unless @options[:token]
          puts @opts
          exit(1)
        end

        Client.new(@options).register!

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
        log.fatal "Error: SCC returned '#{e.message}' (#{e.code})"
        exit 67
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
          @options[:product] = { name: opt.split('/')[0], version: opt.split('/')[1], arch: opt.split('/')[2] }
        end

        @opts.on('-r', '--regcode [REGCODE]', 'Subscription registration code for the',
                 '  product to be registered.',
                 '  Relates that product to the specified subscription,',
                 '  and enables software repositories for that product') do |opt|
          check_if_param(opt, 'Please provide a registration code parameter')
          @options[:token] = opt
        end

        @opts.on('--url [URL]', 'URL of registration server (e.g. https://scc.suse.com).') do |opt|
          check_if_param(opt, 'Please provide registration server URL')
          @options[:url] = opt
        end

        @opts.on('-s', '--status', 'get current system registration status') do |opt|
          @options[:status] = true
        end

        @opts.separator ''
        @opts.separator 'Common options:'

        @opts.on('-d', '--dry-run', 'only print what would be done') do |opt|
          @options[:dry] = opt
        end

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

        @opts.on('-l [LANG]', '--language [LANG]', 'translate error messages into one of LANG which is a',
                 '  comma-separated list of ISO 639-1 codes') do |opt|
          @options[:language] = opt
        end

        @opts.on_tail('-h', '--help', 'show this message') do
          puts @opts
          exit
        end

        @opts.set_summary_width(24)
        @opts.parse(@argv)
        log.info("cmd options: '#{@options}'")

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
