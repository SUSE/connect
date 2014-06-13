require 'open3'

module SUSE
  module Toolkit
    # Provides basic system calls interface
    module SystemCalls
      include Connect::Logger

      def execute(cmd, quiet = true)
        log.debug("Executing: '#{cmd}' Quiet: #{quiet}")

        output, error, status = Open3.capture3(cmd) {|stdin, stdout, stderr, wait_thr| stdout.read }

        if status.exitstatus.zero?
          output.strip unless quiet
        else
          log.error("command '#{cmd}' failed")

          if cmd.include? 'zypper'
            raise Connect::ZypperError, error
          else
            raise Connect::SystemCallError, error
          end
        end
      end

    end
  end
end
