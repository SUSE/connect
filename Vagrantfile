Vagrant.configure('2') do |config|

  config.vm.define :connect do |dummy|
    dummy.vm.box = 'scc_sles12_b1_kvm'

    dummy.vm.provider :libvirt do |domain|
      domain.memory = 256
      domain.cpus = 1
      domain.nested = true
      domain.volume_cache = 'none'
    end

  end

end
