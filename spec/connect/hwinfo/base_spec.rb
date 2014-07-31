require 'spec_helper'

describe SUSE::Connect::HwInfo::Base do
  subject { SUSE::Connect::HwInfo::Base }

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

    context 'not supported architecture' do
      require 'suse/connect/hwinfo/s390'

      it 'returns a hash with hostname and arch' do
        expect(subject).to receive(:x86?).and_return(false)
        expect(subject).to receive(:s390?).and_return(false)

        expect(SUSE::Connect::System).to receive(:hostname).and_return('test')
        expect(subject).to receive(:arch).and_return('not_supported')

        hwinfo = subject.info
        expect(hwinfo.keys).to eq [:hostname, :arch]
        expect(hwinfo[:hostname]).to eq 'test'
        expect(hwinfo[:arch]).to eq 'not_supported'
      end
    end
  end



end
