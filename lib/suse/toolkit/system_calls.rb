require 'open3'

module SUSE
  module Toolkit
    # Provides basic system calls interface
    module SystemCalls
      include Connect::Logger

      def execute(cmd, quiet = true, valid_exit_codes = [0]) # rubocop:disable CyclomaticComplexity
        log.debug("Executing: '#{cmd}' Quiet: #{quiet}")
        output, error, status = Open3.capture3({ 'LC_ALL' => 'C' }, cmd) {|_stdin, stdout, stderr, _wait_thr| stderr.read  + stdout.read }
        log.debug("Output: '#{output.strip}'") unless output.empty?

        # Catching interactive failures of zypper. --non-interactive always returns with exit code 0 here
        if !valid_exit_codes.include?(status.exitstatus) || error.include?('ABORT request')
          log.error("command '#{cmd}' failed")
          log.debug("Error: '#{error.strip}'") unless error.empty?
          # NOTE: zypper with formatter option will return output instead of error
          # e.g. command 'zypper --xmlout --non-interactive products -i' failed
          error = error.empty? ? output.strip : error.strip
          e = (cmd.include? 'zypper') ? Connect::ZypperError.new(status.exitstatus, error) : Connect::SystemCallError
          raise e, error
        end
        output.strip unless quiet
      end
    end
  end
end
