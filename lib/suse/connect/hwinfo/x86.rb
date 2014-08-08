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
      if respond_to?("#{arch}_uuid", true)
        send "#{arch}_uuid"
      else
        log.debug("Not implemented. Unable to determine UUID for #{arch}. Set to nil")
        nil
      end
    end

    private

    # Simple arch abstraction - as means to determine uuid can vary.
    def x86_64_uuid
      if File.file?('/sys/hypervisor/uuid')
        uuid_output = IO.read('/sys/hypervisor/uuid')
      else
        uuid_output = execute('dmidecode -s system-uuid', false)
      end
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
