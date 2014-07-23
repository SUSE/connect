shared_examples_for SUSE::Connect::Archs::X86_64 do

  describe '.hwinfo' do

    let(:lscpu) { File.read(File.join(fixtures_dir, 'lscpu_phys.txt')) }
    let(:success) { double('Process Status', :exitstatus => 0) }

    before :each do
      allow(Open3).to receive(:capture3).with('lscpu').and_return([lscpu, '', success])
      subject.instance_variable_set('@output', nil)
    end

    it 'parses output of lscpu and returns hash' do
      expect(subject.send(:output)).to be_kind_of Hash
      expect(subject.send(:output)).to include 'CPU(s)'
      expect(subject.send(:output)).to include 'Socket(s)'
      expect(subject.send(:output)).to include 'Architecture'
    end

    context 'physical' do
      it 'returns system cpus count' do
        expect(subject.cpus).to eql 8
      end

      it 'returns system sockets count' do
        expect(subject.sockets).to eql 1
      end

      describe '.hypervisor' do
        it 'returns nil' do
          expect(subject.hypervisor).to eql nil
        end
      end
    end

    context 'virtual' do
      let(:lscpu) { File.read(File.join(fixtures_dir, 'lscpu_virt.txt')) }

      before do
        allow(subject).to receive(:execute).with('lscpu', false).and_return(lscpu)
      end

      describe '.hypervisor' do
        it 'returns hypervisor vendor' do
          expect(subject.hypervisor).to eql 'KVM'
        end
      end
    end

    before :each do
      allow(subject).to receive(:uuid).and_return('randomcrypticstring')
      allow(subject).to receive(:execute).with('lscpu', false).and_return(lscpu)
    end

    it 'collects basic hwinfo for x86/x86_64 systems ' do
      allow(subject).to receive(:hostname).and_return('blue_gene')
      allow(subject).to receive(:arch).and_return('blob')
      expect(subject.hwinfo).to eq(
                                    hostname:   'blue_gene',
                                    cpus:        8,
                                    sockets:     1,
                                    hypervisor:  nil,
                                    arch:        'blob',
                                    uuid:        'randomcrypticstring'
                                )
    end

  end

  describe '.uuid' do

    it 'extracts uuid from dmidecode' do
      mock_uuid = '4C4C4544-0059-4810-8034-C2C04F335931'
      allow(subject).to receive(:execute).with('dmidecode -s system-uuid', false).and_return(mock_uuid)
      allow(subject).to receive(:arch).and_return('x86_64')
      expect(subject.uuid).to eq '4C4C4544-0059-4810-8034-C2C04F335931'
    end

    it 'return nil if uuid from dmidecode is Not Settable' do
      mock_uuid = 'Not Settable'
      allow(subject).to receive(:arch).and_return('x86_64')
      allow(subject).to receive(:execute).with('dmidecode -s system-uuid', false).and_return(mock_uuid)
      expect(subject.uuid).to be nil
    end

  end

end
