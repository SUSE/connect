require 'spec_helper'
require 'suse/connect/hwinfo/s390'

describe SUSE::Connect::HwInfo::S390 do

  subject { SUSE::Connect::HwInfo::S390 }
  let(:success) { double('Process Status', :exitstatus => 0) }
  let(:lscpu) { File.read(File.join(fixtures_dir, 'lscpu_phys.txt')) }

  before :each do
    allow(SUSE::Connect::System).to receive(:hostname).and_return('test')
    allow(Open3).to receive(:capture3).with('lscpu').and_return([lscpu, '', success])
    allow(Open3).to receive(:capture3).with('uname -i').and_return(['s390', '', success])
  end

  it 'returns a hwinfo hash for x86/x86_64 systems' do
    # pending
    # hwinfo = subject.hwinfo
    # expect(hwinfo[:hostname]).to eq 'test'
    # expect(hwinfo[:cpus]).to eq 8
    # expect(hwinfo[:sockets]).to eq 1
    # expect(hwinfo[:hypervisor]).to eq nil
    # expect(hwinfo[:arch]).to eq 'x86_64'
    # expect(hwinfo[:uuid]).to eq 'uuid'
  end
end
