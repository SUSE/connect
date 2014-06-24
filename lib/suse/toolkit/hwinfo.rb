require 'suse/toolkit/system_calls'

# Collects system hardware information
module SUSE::Toolkit::Hwinfo
  include SUSE::Toolkit::SystemCalls

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
    @output ||= execute('lscpu', false).split("\n").reduce({}) do |hash, line|
      k, v = line.split(':')
      hash[k] = v.strip
      hash
    end
  end
end
