require 'spec_helper'
require 'suse/connect/hwinfo/arm64'

describe SUSE::Connect::HwInfo::ARM64 do
  subject { SUSE::Connect::HwInfo::ARM64 }
  let(:success) { double('Process Status', exitstatus: 0) }
  let(:lscpu) { File.read(File.join(fixtures_dir, 'lscpu_phys.txt')) }
  let(:dmidecode) { File.read(File.join(fixtures_dir, 'dmidecode_aws.txt')) }
  include_context 'shared lets'

  before :each do
    allow(SUSE::Connect::System).to receive(:hostname).and_return('test')
    allow(Open3).to receive(:capture3).with(shared_env_hash, 'lscpu').and_return([lscpu, '', success])
    allow(Open3).to receive(:capture3).with(shared_env_hash, 'dmidecode -t system').and_return([dmidecode, '', success])
  end

  after(:each) do
    SUSE::Connect::HwInfo::Base.instance_variable_set('@arch', nil)
  end

  it 'returns a hwinfo hash for aarm64 systems' do
    allow(Open3).to receive(:capture3).with(shared_env_hash, 'uname -i').and_return(['aarch64', '', success])
    allow(Open3).to receive(:capture3).with(shared_env_hash, 'dmidecode -s system-uuid').and_return(['uuid', '', success])
    allow(Open3).to receive(:capture3).with(shared_env_hash, 'systemd-detect-virt -v').and_return(['none', '', success])

    hwinfo = subject.hwinfo
    expect(hwinfo[:hostname]).to eq 'test'
    expect(hwinfo[:cpus]).to eq 8
    expect(hwinfo[:sockets]).to eq 1
    expect(hwinfo[:hypervisor]).to eq nil
    expect(hwinfo[:arch]).to eq 'aarch64'
    expect(hwinfo[:uuid]).to eq 'uuid'
    expect(hwinfo[:cloud_provider]).to eq 'Amazon'
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

  describe '.uuid' do
    context :arm64_arch do
      before :each do
        allow(subject).to receive(:arch).and_return('aarch64')
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

      it 'return nil if uuid from dmidecode is Not Present' do
        mock_uuid = 'Not Present'
        allow(subject).to receive(:execute).with('dmidecode -s system-uuid', false).and_return(mock_uuid)
        expect(subject.uuid).to be nil
      end

      it 'returns nil if calling dmidecode fails' do
        allow(subject).to receive(:execute).with('dmidecode -s system-uuid', false) do
          raise Connect::SystemCallError, '/sys/firmware/efi/systab: SMBIOS entry point missing'
        end

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
  end

  describe '.hypervisor' do
    before do
      allow(subject).to receive(:arch).and_return('aarch64')
    end

    context 'systemd is installed' do
      it 'returns nil for hypervisor for non-virtual systems' do
        expect(Open3).to receive(:capture3).with(shared_env_hash, 'systemd-detect-virt -v').and_return(['none', '', success])
        expect(subject.hypervisor).to eql nil
      end

      it 'returns hypervisor vendor for virtual systems' do
        expect(Open3).to receive(:capture3).with(shared_env_hash, 'systemd-detect-virt -v').and_return(['kvm', '', success])
        expect(subject.hypervisor).to eql 'kvm'
      end
    end

    context 'systemd is missing' do
      it 'returns nil when systemd-detect-virt is not found' do
        expect(Open3).to receive(:capture3).with(shared_env_hash, 'systemd-detect-virt -v').and_raise(Errno::ENOENT)
        expect(subject.hypervisor).to eql nil
      end
    end
  end
end
