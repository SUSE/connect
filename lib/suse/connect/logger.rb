module SUSE
  module Connect
    class Logger

      class << self

        def info(msg)
          STDOUT.puts msg
        end

        def error(msg, e=nil)
          STDERR.puts "ERROR: #{msg}#{(' -> ' + e.to_s) if e}"
        end

        def debug(msg)
          STDOUT.puts "DEBUG: #{msg}"
        end

      end
    end
  end
end
