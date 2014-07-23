module SUSE::Connect::Archs::X86

  def hwinfo
    {
      hostname: hostname,
      cpus: cpus,
      sockets: sockets,
      hypervisor: hypervisor,
      arch: arch,
      uuid: uuid
    }
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

  def uuid
    uuid_output = execute('dmidecode -s system-uuid', false)
    uuid_output == 'Not Settable' ? nil : uuid_output
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
