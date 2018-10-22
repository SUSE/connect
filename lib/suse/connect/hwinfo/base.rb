include SUSE::Toolkit::SystemCalls

module SUSE::Connect::HwInfo
  # Base class for hardware information collection
  class Base
    class << self
      def info
        if x86?
          require_relative 'x86'
          X86.hwinfo
        elsif s390?
          require_relative 's390'
          S390.hwinfo
        elsif arm64?
          require_relative 'arm64'
          ARM64.hwinfo
        else
          {
            hostname: hostname,
            arch: arch
          }
        end
      end

      # Delegate hostname to SUSE::Connect::System
      def hostname
        SUSE::Connect::System.hostname
      end

      def arch
        @arch ||= execute('uname -i', false)
      end

      def s390?
        arch == 's390x'
      end

      def x86?
        arch == 'x86_64'
      end

      def arm64?
        arch == 'aarch64'
      end

      def cloud_provider
        regex = /(Version: .*(amazon)|Manufacturer: (Google)|Manufacturer: (Microsoft) Corporation)/
        matches = execute('dmidecode -t system', false).match(regex).to_a[2..4].to_a.compact
        return nil unless matches.length == 1
        matches[0].capitalize
      rescue SUSE::Connect::SystemCallError, Errno::ENOENT
        nil
      end
    end
  end
end
