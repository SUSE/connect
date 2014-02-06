require 'spec_helper'

describe SUSE::Connect::Service do

  subject { SUSE::Connect::Service }

  describe '.new' do

    let :sources_mock do
      { 'a' => 'foo', 'b' => 'bar' }
    end

    it 'assigns sources' do
      subject.new(:sources => sources_mock).sources.should eq(sources_mock)
    end

    it 'assigns norefresh' do
      subject.new(:norefresh => %w{ 1 2 3 }, :sources => sources_mock).norefresh.should eq(%w{1 2 3})
    end

    it 'assigns enabled' do
      subject.new(:enabled => %w{ 1 2 3 }, :sources => sources_mock).enabled.should eq(%w{1 2 3})
    end

    it 'set enabled to empty array if not passed' do
      subject.new(:sources => sources_mock).enabled.should eq([])
    end

    it 'set norefresh to empty array if not passed' do
      subject.new(:sources => sources_mock).norefresh.should eq([])
    end

    it 'raise if no sources passed' do
      expect { subject.new }.to raise_error ArgumentError, 'missing keyword: sources'
    end

  end
end
