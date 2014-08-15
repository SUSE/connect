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
            # NOTE: zypper with formatter option will return output instead of error
            # e.g. command 'zypper --xmlout --non-interactive products -i' failed
            error = error.empty? ? output : error

            e = Connect::ZypperError.new(status.exitstatus, cmd, error)
            raise e, error
          else
            raise Connect::SystemCallError, error
          end
        end
      end

    end
  end
end
