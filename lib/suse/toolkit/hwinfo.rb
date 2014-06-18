require 'suse/toolkit/system_calls'

module SUSE
  module Toolkit
    module Hwinfo
      include SUSE::Toolkit::SystemCalls

      def hostname
        execute('hostname', false)
      end

      def cpus
        output['CPU(s)'].to_i
      end

      def sockets
        output['Socket(s)'].to_i
      end

      def hypervisor
        output['Hypervisor vendor']
      end

      def arch
        output['Architecture']
      end

      private
      def output
        @output ||= execute('lscpu', false).split("\n").inject({}) do |hash, line|
          k,v = line.split(':')
          hash[k] = v.strip
          hash
        end
      end
    end
  end
end
