require 'spec_helper'
require 'etc'

describe SUSE::Toolkit::CurlrcDotfile do

  let(:curlrc_location) { File.join(Etc.getpwuid.dir, described_class::CURLRC_LOCATION) }
  let(:fixture_curlrc) { File.readlines('spec/fixtures/curlrc_example.dotfile') }
  let(:proper_line_with_credentials) do %Q(--proxy-user "meuser:mepassord"
) end
  let(:garbled_line_with_credentials) do %Q(--proxy-user meusermepassord"
) end

  subject { described_class.new }

  describe '.new' do

    it 'builds location to assumed curlrc' do
      expect(subject.instance_variable_get('@file_location')).to eq curlrc_location
    end

  end

  describe '#exist?' do

    it 'returns false if no curlrc is not found' do
      allow(File).to receive(:exist?).with(curlrc_location).and_return false
      expect(subject.exist?).to be false
    end

    it 'returns true if no curlrc is found' do
      allow(File).to receive(:exist?).with(curlrc_location).and_return true
      expect(subject.exist?).to be true
    end

  end

  describe '#password' do

    context 'string with credentials is matching' do

      before do
        allow(subject).to receive(:line_with_credentials).and_return(proper_line_with_credentials)
      end

      it 'extracts proper username' do
        expect(subject.password).to eq 'mepassord'
      end

    end

    context 'string with credentials is not matching' do

      before do
        allow(subject).to receive(:line_with_credentials).and_return(garbled_line_with_credentials)
      end

      it 'extracts proper username' do
        expect(subject.password).to be nil
      end

    end

  end

  describe '#username' do

    context 'string with credentials is matching' do

      before do
        allow(subject).to receive(:line_with_credentials).and_return(proper_line_with_credentials)
      end

      it 'extracts proper username' do
        expect(subject.username).to eq 'meuser'
      end

    end

    context 'string with credentials is not matching' do

      before do
        allow(subject).to receive(:line_with_credentials).and_return(garbled_line_with_credentials)
      end

      it 'extracts proper username' do
        expect(subject.username).to be nil
      end

    end

  end

  describe '#line_with_credentials' do

    context :file_exist do

      before do
        allow(subject).to receive(:exist?).and_return(true)
        allow(File).to receive(:readlines).with(curlrc_location).and_return(fixture_curlrc)
      end

      it 'returns line matching pattern' do
        expect(subject.send(:line_with_credentials)).to eq proper_line_with_credentials
      end

      it 'returns nil if no matchin line found' do
        allow(File).to receive(:readlines).with(curlrc_location).and_return(%w{ foo bar})
        expect(subject.send(:line_with_credentials)).to be nil
      end

    end

    context :file_does_not_exist do

      before { allow(subject).to receive(:exist?).and_return(false) }

      it 'memoizes lines been read from file' do
        first_call = subject.send(:line_with_credentials)
        expect(subject.send(:line_with_credentials)).to be first_call
      end

      it 'holds array' do
        expect(subject.send(:line_with_credentials)).to be_kind_of NilClass
      end

    end

  end

end
