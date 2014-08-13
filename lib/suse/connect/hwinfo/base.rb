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
        @@arch ||= execute('uname -i', false)
      end

      def s390?
        arch == 's390x'
      end

      def x86?
        arch == 'x86_64'
      end

    end

  end
end
