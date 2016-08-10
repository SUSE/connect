# Collect hardware information for aarch64 systems
class SUSE::Connect::HwInfo::ARM64 < SUSE::Connect::HwInfo::Base
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
      vendor = execute('systemd-detect-virt -v', false, [0, 1])
      vendor == 'none' ? nil : vendor
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
    def aarch64_uuid
      # INFO: bnc#890881 read the uuid generated by the hypervisor (SLES for EC2)
      begin
        if File.exist?('/sys/hypervisor/uuid')
          uuid_output = File.read('/sys/hypervisor/uuid').chomp
        else
          uuid_output = execute('dmidecode -s system-uuid', false)
        end
      rescue
        uuid_output = nil
      end

      ['Not Settable', 'Not Present'].include?(uuid_output) ? nil : uuid_output
    end

    def output
      @output ||= execute('lscpu', false).split("\n").each_with_object({}) do |line, hash|
        k, v = line.split(':')
        hash[k] = v.strip if v
      end
    end
  end
end
