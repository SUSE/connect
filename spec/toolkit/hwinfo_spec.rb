require 'spec_helper'

# rubocop:disable Documentation
class DummyReceiver
  include SUSE::Toolkit::Hwinfo
end

describe SUSE::Toolkit::Hwinfo do

  subject { DummyReceiver.new }

  let(:success) { double('Process Status', :exitstatus => 0) }
  let(:lscpu) { File.read(File.join(fixtures_dir, 'lscpu_phys.txt')) }

  before :each do
    allow(Open3).to receive(:capture3).with('lscpu').and_return([lscpu, '', success])
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

    it 'returns system architecture' do
      expect(subject.arch).to eql 'x86_64'
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

  describe '.uuid' do

    context :x86_64_arch do

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

    context :arch_with_no_uuid_implementation do

      it 'set uuid to nil' do
        allow(subject).to receive(:arch).and_return('megusta')
        expect(subject.uuid).to be nil
      end

      it 'produces debug log message' do
        allow(subject).to receive(:arch).and_return('carbon')
        expect(subject.log).to receive(:debug).with('Not implemented. Unable to determine UUID for carbon. Set to nil')
        subject.uuid
      end

    end

  end

end
