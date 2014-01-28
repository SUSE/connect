require 'optparse'

class SUSE::Connect::Cli

  def initialize(argv)
    @argx = argv
    @options = {}
    extract_options
  end

  
  private

    def extract_options
      OptionParser.new do |opts|
        opts.banner = 'Usage: SUSEConnect [options]'

        opts.on('-h', '--host [HOST]', 'Connection host.') do |opt|
          @options[:host] = opt
        end

        opts.on('-p', '--port [PORT]', 'Connection port.') do |opt|
          @options[:port] = opt
        end

        opts.on('-t', '--token [TOKEN]', 'Registration token.') do |opt|
          @options[:port] = opt
        end

        opts.separator ''
        opts.separator 'Common options:'

        opts.on('-d', '--dry-mode', 'Dry mode. Does not make any changes to the system.') do |opt|
          @options[:dry] = opt
        end

        opts.on_tail('--version', 'Print version') do
          puts SUSE::Connect::VERSION
        end

        opts.on_tail('--help', 'Show this message.') do
          puts opts
          exit
        end

        opts.on('-v', '--verbose', 'Run verbosely.') do |opt|
          @options[:verbose] = opt
        end

      end.parse!
    end

end
