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
        extract_options
      end

      def execute! # rubocop:disable MethodLength
        log.info(@options) if @options[:verbose]
        Client.new(@options).register!
      rescue ApiError => e
        log.error "ApiError with response: #{e.body} Code: #{e.code}"
        exit 1
      rescue Errno::ECONNREFUSED
        log.error 'connection refused by server'
        exit 1
      rescue JSON::ParserError
        log.error 'cannot parse response from server'
        exit 1
      rescue Errno::EACCES
        log.error 'access error - cannot create required folder/file'
        exit 1
      end

      private

      def extract_options # rubocop:disable MethodLength

        @opts = OptionParser.new

        @opts.separator 'Register SUSE Linux Enterprise installations with the SUSE Customer Center.'
        @opts.separator 'Registration allows access to software repositories including updates,'
        @opts.separator 'and allows online management of subscriptions and organisations'
        @opts.separator ''
        @opts.separator 'Manage subscriptions at https://scc.suse.com'
        @opts.separator ''

        @opts.on('-r', '--regcode [REGCODE]', 'Subscription registration code for the',
                 '  base SUSE Linux Enterprise product on this system.',
                 '  Relates this installation to the specified subscription,',
                 '  and enables software repositories for the base product') do |opt|
          check_if_param(opt, 'Please provide a registration code parameter')
          @options[:token] = opt
        end

        @opts.on('-k', '--insecure', 'Skip SSL verification (insecure).') do |opt|
          @options[:insecure] = opt
        end

        @opts.on('--url [URL]', 'URL of registration server (e.g. https://scc.suse.com).') do |opt|
          check_if_param(opt, 'Please provide registration server URL')
          @options[:url] = opt
        end

        @opts.separator ''
        @opts.separator 'Common options:'

        @opts.on('-d', '--dry-run', 'only print what would be done') do |opt|
          @options[:dry] = opt
        end

        @opts.on('--version', "print program version") do
          puts VERSION
          exit
        end

        @opts.on('-v', '--verbose', 'provide verbose output') do |opt|
          @options[:verbose] = opt
          SUSE::Connect::GlobalLogger.instance.log.level = ::Logger::INFO if opt
        end

        @opts.on('-l [LANG]', '--language [LANG]', 'Translate error messages into one of LANG which is a', '  comma-separated list of ISO 639-1 codes') do |opt|
          @options[:language] = opt
        end

        @opts.on_tail('-h', '--help', 'show this message') do
          puts @opts
          exit
        end

        @opts.set_summary_width(24)
        @opts.parse!

      end

      def check_if_param(opt, message)
        unless opt
          puts message
          exit 1
        end
      end

    end
  end
end
