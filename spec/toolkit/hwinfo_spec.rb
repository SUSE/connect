require 'spec_helper'

# rubocop :(
class DummyReceiver
  include SUSE::Toolkit::Hwinfo
end

describe SUSE::Toolkit::Hwinfo do

  subject { DummyReceiver.new }
  let(:success) { double('Process Status', :exitstatus => 0) }

  it 'parses output of lscpu and returns hash' do
    expect(subject.send(:output)).to be_kind_of Hash
    expect(subject.send(:output)).to include 'CPU(s)'
    expect(subject.send(:output)).to include 'Socket(s)'
    expect(subject.send(:output)).to include 'Architecture'
  end

  context 'physical' do
    let(:lscpu) { File.read(File.join(fixtures_dir, 'lscpu_phys.txt')) }

    before :each do
      allow(Open3).to receive(:capture3).with('lscpu').and_return([lscpu, '', success])
    end

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
end
