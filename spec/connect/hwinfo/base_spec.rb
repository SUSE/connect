require 'spec_helper'

describe SUSE::Connect::HwInfo::Base do
  subject { SUSE::Connect::HwInfo::Base }
  let(:exit_status) { double('Process Status', exitstatus: 0) }
  include_context 'shared lets'

  after do
    SUSE::Connect::HwInfo::Base.instance_variable_set('@arch', nil)
  end

  describe '#cloud_provider' do
    let(:dmidecode_output) { '' }

    before do
      allow(Open3).to receive(:capture3).with(shared_env_hash, 'dmidecode -t system').and_return([dmidecode_output, '', exit_status])
    end

    it 'handles non-cloud providers' do
      expect(subject.cloud_provider).to be_nil
    end

    context 'the dmidecode command fails' do
      let(:exit_status) { double('Process Status', exitstatus: 1) }

      it 'returns nil' do
        expect(subject.cloud_provider).to be_nil
      end
    end

    context 'the dmidecode command is not installed' do
      before do
        allow(Open3).to receive(:capture3).with(shared_env_hash, 'dmidecode -t system').and_raise(Errno::ENOENT)
      end

      it 'returns nil' do
        expect(subject.cloud_provider).to be_nil
      end
    end

    context 'on AWS hypervisors' do
      context 'on regular instances' do
        let(:dmidecode_output) { File.read(File.join(fixtures_dir, 'dmidecode_aws.txt')) }
        it 'detects the provider' do
          expect(subject.cloud_provider).to eq('Amazon')
        end
      end

      context 'on large instances' do
        let(:dmidecode_output) { File.read(File.join(fixtures_dir, 'dmidecode_aws_large.txt')) }
        it 'detects the provider' do
          expect(subject.cloud_provider).to eq('Amazon')
        end
      end
    end

    context 'on Google hypervisors' do
      let(:dmidecode_output) { File.read(File.join(fixtures_dir, 'dmidecode_google.txt')) }

      it 'detects the provider' do
        expect(subject.cloud_provider).to eq('Google')
      end
    end

    context 'on Azure hypervisors' do
      let(:dmidecode_output) { File.read(File.join(fixtures_dir, 'dmidecode_azure.txt')) }

      it 'detects the provider' do
        expect(subject.cloud_provider).to eq('Microsoft')
      end
    end
  end

  describe '#info' do
    context 'x86' do
      require 'suse/connect/hwinfo/x86'

      it 'requires and calls hwinfo class based on system architecture' do
        expect(subject).to receive(:x86?).and_return(true)
        expect(subject).to receive(:require_relative).with('x86')
        expect(SUSE::Connect::HwInfo::X86).to receive(:hwinfo)
        subject.info
      end
    end

    context 's390' do
      require 'suse/connect/hwinfo/s390'

      it 'requires and calls hwinfo class based on system architecture' do
        expect(subject).to receive(:x86?).and_return(false)
        expect(subject).to receive(:s390?).and_return(true)

        expect(subject).to receive(:require_relative).with('s390')
        expect(SUSE::Connect::HwInfo::S390).to receive(:hwinfo)
        subject.info
      end
    end

    context 'arm64' do
      require 'suse/connect/hwinfo/arm64'

      it 'requires and calls hwinfo class based on system architecture' do
        expect(subject).to receive(:x86?).and_return(false)
        expect(subject).to receive(:s390?).and_return(false)
        expect(subject).to receive(:arm64?).and_return(true)

        expect(subject).to receive(:require_relative).with('arm64')
        expect(SUSE::Connect::HwInfo::ARM64).to receive(:hwinfo)
        subject.info
      end
    end

    context 'not supported architecture' do
      it 'returns a hash with hostname and arch' do
        expect(subject).to receive(:x86?).and_return(false)
        expect(subject).to receive(:s390?).and_return(false)
        expect(subject).to receive(:arm64?).and_return(false)

        expect(SUSE::Connect::System).to receive(:hostname).and_return('test')
        expect(subject).to receive(:arch).and_return('not_supported')

        hwinfo = subject.info
        expect(hwinfo.keys).to eq [:hostname, :arch]
        expect(hwinfo[:hostname]).to eq 'test'
        expect(hwinfo[:arch]).to eq 'not_supported'
      end
    end
  end

  describe '#hostname' do
    it 'delegates hostname to SUSE::Connect::System.hostname' do
      expect(SUSE::Connect::System).to receive(:hostname).and_return('hostname')
      expect(subject.hostname).to eql 'hostname'
    end
  end

  describe '#arch' do
    it 'returns the system architecture' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'uname -i').and_return(['blob', '', exit_status])
      expect(subject.arch).to eql 'blob'
    end
  end

  describe '#x86?' do
    it 'returns true if the system architecture is x86 or x86_64' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'uname -i').and_return(['x86_64', '', exit_status])
      expect(subject.x86?).to eql true
    end

    it 'returns false if the system architecture is not x86 or x86_64' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'uname -i').and_return(['blob', '', exit_status])
      expect(subject.x86?).to eql false
    end
  end

  describe '#s390?' do
    it 'returns true if the system architecture is s390x' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'uname -i').and_return(['s390x', '', exit_status])
      expect(subject.s390?).to eql true
    end

    it 'returns false if the system architecture is not s390x' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'uname -i').and_return(['blob', '', exit_status])
      expect(subject.s390?).to eql false
    end
  end

  describe '#arm64?' do
    it 'returns true if the system architecture is aarch64' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'uname -i').and_return(['aarch64', '', exit_status])
      expect(subject.arm64?).to eql true
    end

    it 'returns false if the system architecture is not aarch64' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, 'uname -i').and_return(['blob', '', exit_status])
      expect(subject.s390?).to eql false
    end
  end
end
