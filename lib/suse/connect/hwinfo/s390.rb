# Collect hardware information for s390x systems
class SUSE::Connect::HwInfo::S390 < SUSE::Connect::HwInfo::Base
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
      output['VM00 CPUs Total'].to_i
    end

    def sockets
      output['VM00 IFLs'].to_i
    end

    def hypervisor
      # Strip and remove recurring whitespaces e.g. " z/VM    6.1.0" => "z/VM 6.1.0"
      output['VM00 Control Program'].strip.sub('   ', '')
    end

    def uuid
      read_values = execute('read_values -u', false)
      uuid = read_values.empty? ? nil : read_values

      log.debug("Not implemented. Unable to determine UUID for #{arch}. Set to nil") unless uuid
      uuid
    end

    private

    def output
      @output ||= Hash[execute('read_values -s', false).split("\n").map {|line| line.split(':') }]
    end
  end
end
