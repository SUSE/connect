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

        unless @options[:token]
          puts @opts
          exit
        end
        Client.new(@options).register!

      rescue ApiError => e
        log.error "Error: SCC returned '#{e.message}'"
        exit 1
      rescue Errno::ECONNREFUSED
        log.error 'Error: Connection refused by server'
        exit 1
      rescue JSON::ParserError
        log.error 'Error: Cannot parse response from server'
        exit 1
      rescue Errno::EACCES => e
        log.error "Error: Access error - #{e.message}"
        exit 1
      end

      private

      def extract_options # rubocop:disable MethodLength

        @opts = OptionParser.new

        @opts.banner = 'SUSEConnect is a command line tool for connecting a client system to the SUSE Customer Center.'
        @opts.separator 'It will connect the system to your product subscriptions and enable the product ' \
                        'repositories/services locally.'
        @opts.separator ''
        @opts.separator 'Please visit https://scc.suse.com to see and manage your subscriptions.'
        @opts.separator ''
        @opts.separator 'Usage: SUSEConnect [options]'

        @opts.on('-p', '--product [PRODUCT]', 'Product to activate (default: the system\'s baseproduct). ' \
                                        'For installed products you can find these values by calling: ' \
                                        'zypper products\'. Format: <name>-<version>-<architecture>') do |opt|
          check_if_param(opt, 'Please provide a product identifier')
          check_if_param((opt =~ /\S+-\S+-\S+/), 'Please provide the product identifier in this format: ' \
            '<name>-<version>-<architecture>. For installed products you can find these values by calling: ' \
            '\'zypper products\'. ')
          @options[:product] = { :name => opt.split('-')[0], :version => opt.split('-')[1],
                                 :arch => opt.split('-')[2] }
        end

        @opts.on('-r', '--regcode [REGCODE]', 'Registration code. The repositories of the subscription with this ' \
                                              'registration code will get activated on this system.') do |opt|
          check_if_param(opt, 'Please provide a registration code parameter')
          @options[:token] = opt
        end

        @opts.on('-k', '--insecure', 'Skip SSL verification (insecure).') do |opt|
          @options[:insecure] = opt
        end

        @opts.on('--url [URL]', 'Connection base url (e.g. https://scc.suse.com).') do |opt|
          check_if_param(opt, 'Please provide url parameter')
          @options[:url] = opt
        end

        @opts.separator ''
        @opts.separator 'Common options:'

        @opts.on('-d', '--dry-mode', 'Dry mode. Does not make any changes to the system.') do |opt|
          @options[:dry] = opt
        end

        @opts.on('--version', 'Print version') do
          puts VERSION
          exit
        end

        @opts.on('-h', '--help', 'Show this message.') do
          puts @opts
          exit
        end

        @opts.on('-v', '--verbose', 'Run verbosely.') do |opt|
          @options[:verbose] = opt
          SUSE::Connect::GlobalLogger.instance.log.level = ::Logger::DEBUG if opt
        end

        @opts.on('-l [LANG]', '--language [LANG]', 'comma-separated list of ISO 639-1 codes') do |opt|
          @options[:language] = opt
        end

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
