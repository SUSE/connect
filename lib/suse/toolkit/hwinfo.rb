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
    execute('uname -i', false)
  end

  def uuid
    if respond_to?("#{arch}_uuid", true)
      send "#{arch}_uuid"
    else
      log.debug("Not implemented. Unable to determine UUID for #{arch}. Set to nil")
      nil
    end
  end

  private

  # simple arch abstraction - as means to determine uuid can vary.
  def x86_64_uuid
    uuid_output = execute('dmidecode -s system-uuid', false)
    uuid_output == 'Not Settable' ? nil : uuid_output
  end

  def output
    @output ||= execute('lscpu', false).split("\n").reduce({}) do |hash, line|
      k, v = line.split(':')
      hash[k] = v.strip
      hash
    end
  end
end
