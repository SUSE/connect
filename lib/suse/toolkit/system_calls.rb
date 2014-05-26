module SUSE
  module Toolkit
    # Provides basic system calls interface
    module SystemCalls
      include Connect::Logger

      def call(command)
        log.debug("Calling: '#{command}'")
        system(command) ? true : log.error("command '#{command}' failed")
      end

      def call_with_output(command)
        log.debug("Calling: '#{command}'")
        `#{command}`.chomp
      end

    end
  end
end
