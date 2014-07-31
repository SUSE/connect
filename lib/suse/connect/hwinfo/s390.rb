# Collect hardware information for s390x systems
class SUSE::Connect::HwInfo::S390 < SUSE::Connect::HwInfo::Base
  class << self
    def hwinfo
    #   {
    #     hostname: hostname,
    #     cpus: cpus,
    #     sockets: sockets,
    #     hypervisor: hypervisor,
    #     arch: arch,
    #     uuid: uuid
    #   }
    end
  end
end
