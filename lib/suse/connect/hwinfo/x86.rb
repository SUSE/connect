# Collect hardware information for x86/x86_64 systems
class SUSE::Connect::HwInfo::X86 < SUSE::Connect::HwInfo::Base
  class << self
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
      read_values = execute('read_values -u', false)
      uuid = read_values.empty? ? nil : read_values

      log.debug("Not implemented. Unable to determine UUID for #{arch}. Set to nil") unless uuid
      uuid
    end

    private

    # Simple arch abstraction - as means to determine uuid can vary.
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
end
