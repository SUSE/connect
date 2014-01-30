require 'singleton'

module SUSE
  module Connect
    class Logger

      class << self

        def info(msg)
          STDOUT.puts "#{msg}"
        end

        def error(msg)
          STDERR.puts "ERROR: #{msg}"
        end

        def debug(msg)
          STDOUT.puts "DEBUG: #{msg}"
        end

      end
    end
  end
end
