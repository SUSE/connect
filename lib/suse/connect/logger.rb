require 'logger'
require 'singleton'

module SUSE
  module Connect
    # the default logger
    class DefaultLogger < ::Logger
      def initialize(*args)
        super(*args)
        self.level = ::Logger::INFO
        # by default log only the message
        self.formatter = proc do |_severity, _datetime, _progname, msg|
          "#{msg}\n"
        end
      end
    end

    # Singleton log instance used by SUSE::Connect::Logger module
    #
    # @example Set own logger
    #   GlobalLogger.instance.log = ::Logger.new($stderr)
    #
    # Used by YaST already, do not refactor without consulting them!
    # Passing the YaST logger for writing the log to /var/log/YaST2/y2log (#log=)
    class GlobalLogger
      include Singleton

      attr_accessor :log

      def initialize
        @log = DefaultLogger.new($stdout)
      end
    end

    # Module provides access to specific logging. To set logging see GlobalLogger.
    #
    # @example Add logging to class
    #   class A
    #     include ::SUSE::Connect::Logger
    #
    #     def self.f
    #       log.info "self f"
    #     end
    #
    #     def a
    #       log.debug "a"
    #     end
    #   end
    module Logger
      def log
        GlobalLogger.instance.log
      end

      def self.included(base)
        base.extend self
      end

      def green
        "\e[32m#{self}\e[0m"
      end

      def red
        "\e[31m#{self}\e[0m"
      end

      def bold
        "\e[1m#{self}\e[22m"
      end
    end
  end
end
