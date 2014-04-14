module SUSE
  module Toolkit
    # Provides basic system calls interface
    module SystemCalls
      class ErrorWithStatus < StandardError
        attr_accessor :code

        def initialize(code)
          @code = code
        end
      end

      include Connect::Logger

      def call(command)
        system(command) ? true : log.error("command `#{command}` failed")
      end

      def call_with_output(command)
        output = `#{command}`.chomp
        if $?
          raise ErrorWithStatus.new($?.exitstatus) unless $?.success?
        end
        output
      end

    end
  end
end
