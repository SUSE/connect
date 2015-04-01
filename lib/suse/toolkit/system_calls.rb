require 'open3'

module SUSE
  module Toolkit
    # Provides basic system calls interface
    module SystemCalls
      include Connect::Logger

      def execute(cmd, quiet = true) # rubocop:disable CyclomaticComplexity
        log.debug("Executing: '#{cmd}' Quiet: #{quiet}")
        output, error, status = Open3.capture3({'LC_ALL' => 'C'}, cmd) {|stdin, stdout, stderr, wait_thr| stdout.read }
        log.debug("Output: '#{output.strip}'") unless output.empty?

        # Catching interactive failures of zypper. --non-interactive always returns with exit code 0 here
        if !status.exitstatus.zero? || error.include?('ABORT request')
          log.error("command '#{cmd}' failed")
          log.debug("Error: '#{error.strip}'") unless error.empty?
          # NOTE: zypper with formatter option will return output instead of error
          # e.g. command 'zypper --xmlout --non-interactive products -i' failed
          error = error.empty? ? output.strip : error.strip

          if cmd.include? 'zypper'
            e = Connect::ZypperError.new(status.exitstatus, error)
            raise e, error
          else
            raise Connect::SystemCallError, error
          end
        end
        output.strip unless quiet
      end

    end
  end
end
