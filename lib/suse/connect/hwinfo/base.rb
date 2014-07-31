include SUSE::Toolkit::SystemCalls

module SUSE::Connect::HwInfo
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
            hostname: SUSE::Connect::System.hostname,
            arch: arch
          }
        end
      end

      def arch
        execute('uname -i', false)
      end

      def s390?
        %w{s390x}.include? arch
      end

      def x86?
        %w{x86, x86_64}.include? arch
      end
    end
  end
end
