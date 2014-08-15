require 'spec_helper'
require 'suse/connect/hwinfo/x86'

describe SUSE::Connect::HwInfo::X86 do

  subject { SUSE::Connect::HwInfo::X86 }
  let(:success) { double('Process Status', :exitstatus => 0) }
  let(:lscpu) { File.read(File.join(fixtures_dir, 'lscpu_phys.txt')) }

  before :each do
    allow(SUSE::Connect::System).to receive(:hostname).and_return('test')
    allow(Open3).to receive(:capture3).with('lscpu').and_return([lscpu, '', success])
  end

  after(:each) do
    SUSE::Connect::HwInfo::Base.class_variable_set('@@arch', nil)
  end

  it 'returns a hwinfo hash for x86/x86_64 systems' do
    allow(Open3).to receive(:capture3).with('uname -i').and_return(['x86_64', '', success])
    expect(Open3).to receive(:capture3).with('dmidecode -s system-uuid').and_return(['uuid', '', success])

    hwinfo = subject.hwinfo
    expect(hwinfo[:hostname]).to eq 'test'
    expect(hwinfo[:cpus]).to eq 8
    expect(hwinfo[:sockets]).to eq 1
    expect(hwinfo[:hypervisor]).to eq nil
    expect(hwinfo[:arch]).to eq 'x86_64'
    expect(hwinfo[:uuid]).to eq 'uuid'
  end

  it 'parses output of lscpu and returns hash' do
    expect(subject.send(:output)).to be_kind_of Hash
    expect(subject.send(:output)).to include 'CPU(s)'
    expect(subject.send(:output)).to include 'Socket(s)'
    expect(subject.send(:output)).to include 'Architecture'
  end

  it 'returns system cpus count' do
    expect(subject.cpus).to eql 8
  end

  it 'returns system sockets count' do
    expect(subject.sockets).to eql 1
  end

  it 'returns nil for hypervisor' do
    expect(subject.hypervisor).to eql nil
  end

  it 'returns hypervisor vendor for virtual systems' do
    expect(subject).to receive(:output).and_return('Hypervisor vendor' => 'KVM')
    expect(subject.hypervisor).to eql 'KVM'
  end

  describe '.uuid' do
    context :x86_64_arch do
      before :each do
        allow(subject).to receive(:arch).and_return('x86_64')
      end

      it 'extracts uuid from dmidecode' do
        mock_uuid = '4C4C4544-0059-4810-8034-C2C04F335931'
        allow(subject).to receive(:execute).with('dmidecode -s system-uuid', false).and_return(mock_uuid)
        expect(subject.uuid).to eq '4C4C4544-0059-4810-8034-C2C04F335931'
      end

      it 'return nil if uuid from dmidecode is Not Settable' do
        mock_uuid = 'Not Settable'
        allow(subject).to receive(:execute).with('dmidecode -s system-uuid', false).and_return(mock_uuid)
        expect(subject.uuid).to be nil
      end

      context 'SLES for EC2' do
        it 'extracts uuid from /sys/hypervisor/uuid file' do
          uuid_file = '/sys/hypervisor/uuid'
          mock_uuid = "4C4C4544-0059-4810-8034-C2C04F335931\n"

          expect(File).to receive(:exist?).with(uuid_file).and_return(true)
          expect(File).to receive(:read).with(uuid_file).and_return(mock_uuid)
          expect(subject.uuid).to eq '4C4C4544-0059-4810-8034-C2C04F335931'
        end
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
