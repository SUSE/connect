require 'spec_helper'
require 'suse/connect/hwinfo/s390'

describe SUSE::Connect::HwInfo::S390 do
  subject { SUSE::Connect::HwInfo::S390 }
  let(:success) { double('Process Status', :exitstatus => 0) }
  let(:read_values) { File.read(File.join(fixtures_dir, 'read_values_s.txt')) }
  include_context "shared lets"

  before :each do
    allow(Open3).to receive(:capture3).with(shared_env_hash, 'uname -i').and_return(['s390x', '', success])
    allow(SUSE::Connect::System).to receive(:hostname).and_return('test')
    allow(Open3).to receive(:capture3).with(shared_env_hash, 'read_values -s').and_return([read_values, '', success])
  end

  after(:each) do
    SUSE::Connect::HwInfo::Base.instance_variable_set('@arch', nil)
  end

  it 'returns a hwinfo hash for x86/x86_64 systems' do
    expect(Open3).to receive(:capture3).with(shared_env_hash, 'read_values -u').and_return(['', '', success])

    hwinfo = subject.hwinfo
    expect(hwinfo[:hostname]).to eq 'test'
    expect(hwinfo[:cpus]).to eq 1
    expect(hwinfo[:sockets]).to eq 1
    expect(hwinfo[:hypervisor]).to eq 'z/VM 6.1.0'
    expect(hwinfo[:arch]).to eq 's390x'
    expect(hwinfo[:uuid]).to eq nil
  end

  it 'returns system cpus count' do
    expect(subject.cpus).to eql 1
  end

  it 'returns system sockets count' do
    expect(subject.sockets).to eql 1
  end

  it 'returns system hypervisor' do
    expect(subject.hypervisor).to eql 'z/VM 6.1.0'
  end

  describe '#uuid' do
    it 'returns nil if uuid is not set' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'read_values -u').and_return(['', '', success])
      expect(subject.uuid).to eql nil
    end

    it 'returns system uuid' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'read_values -u').and_return(['12345-67890-abcde', '', success])
      expect(subject.uuid).to eql '12345-67890-abcde'
    end
  end

  it 'parses output of read_values and returns hash' do
    expect(subject.send(:output)).to be_kind_of Hash
    expect(subject.send(:output)).to include 'VM00 CPUs Total'
    expect(subject.send(:output)).to include 'VM00 IFLs'
    expect(subject.send(:output)).to include 'VM00 Control Program'
  end
end
