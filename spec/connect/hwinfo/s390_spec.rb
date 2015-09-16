require 'spec_helper'
require 'suse/connect/hwinfo/s390'

describe SUSE::Connect::HwInfo::S390 do
  subject { SUSE::Connect::HwInfo::S390 }
  let(:read_values) { File.read(File.join(fixtures_dir, 'read_values_s.txt')) }
  let(:success) { double('Process Status', :exitstatus => 0) }
  include_context 'shared lets'

  before :each do
    allow(Open3).to receive(:capture3).with(shared_env_hash, 'uname -i').and_return(['s390x', '', success])
    allow(SUSE::Connect::System).to receive(:hostname).and_return('test')
    allow(Open3).to receive(:capture3).with(shared_env_hash, 'read_values -s').and_return([read_values, '', success])
  end

  after(:each) do
    SUSE::Connect::HwInfo::Base.instance_variable_set('@arch', nil)
    SUSE::Connect::HwInfo::S390.instance_variable_set('@output', nil)
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

  context 'Virtual' do
    it 'returns a hwinfo hash for virtual s390 systems' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'read_values -u').and_return(['', '', success])

      hwinfo = subject.hwinfo
      expect(hwinfo[:hostname]).to eq 'test'
      expect(hwinfo[:cpus]).to eq 1
      expect(hwinfo[:sockets]).to eq 1
      expect(hwinfo[:hypervisor]).to eq 'z/VM 6.1.0'
      expect(hwinfo[:arch]).to eq 's390x'
      expect(hwinfo[:uuid]).to eq nil
    end

    it 'returns system hypervisor' do
      expect(subject.hypervisor).to eql 'z/VM 6.1.0'
    end
  end

  context 'Physical' do
    let(:read_values) { File.read(File.join(fixtures_dir, 'read_values_s_lpar.txt')) }

    before :each do
      allow(Open3).to receive(:capture3).with(shared_env_hash, 'read_values -s').and_return([read_values, '', success])
      allow(Open3).to receive(:capture3).with(shared_env_hash, 'read_values -u').and_return(['', '', success])
    end

    it 'returns a hwinfo hash for physical s390 systems' do
      hwinfo = subject.hwinfo
      expect(hwinfo[:hostname]).to eq 'test'
      expect(hwinfo[:cpus]).to eq 2
      expect(hwinfo[:sockets]).to eq 2
      expect(hwinfo[:hypervisor]).to eq nil
      expect(hwinfo[:arch]).to eq 's390x'
      expect(hwinfo[:uuid]).to eq nil
    end

    it 'returns no hypervisor when running on an LPAR' do
      expect(SUSE::Connect::HwInfo::S390.hypervisor).to be nil
    end
  end

end
