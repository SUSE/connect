require 'spec_helper'
require 'suse/toolkit/system_calls'

describe SUSE::Toolkit::SystemCalls do

  subject { Open3 }
  let(:date) { 'Fr 13. Jun 10:50:53 CEST 2014' }
  let(:success) { double('Process Status', :exitstatus => 0) }
  let(:failure) { double('Process Status', :exitstatus => 1) }
  let(:error_message) { 'Root privileges are required for installing or uninstalling packages' }

  include SUSE::Toolkit::SystemCalls

  before do
    subject.send(:include, SUSE::Toolkit::SystemCalls)
  end

  describe '.execute' do

    it 'should make a quiet system call' do
      subject.should_receive(:capture3).with('date').and_return([date, '', success])
      execute('date').should be nil
    end

    it 'should produce debug log output' do
      SUSE::Connect::GlobalLogger.instance.log.should_receive(:debug)
      subject.should_receive(:capture3).with('date').and_return([date, '', success])
      expect(execute('date', false)).to eql date
    end

    it 'should produce error log output' do
      SUSE::Connect::GlobalLogger.instance.log.should_receive(:error)

      subject.should_receive(:capture3).with('unknown').and_return(['', error_message, failure])
      expect { execute('unknown') }.to raise_error(SUSE::Connect::SystemCallError, error_message)
    end

    it 'should make a system call and return output from system' do
      subject.should_receive(:capture3).with('date').and_return([date, '', success])
      expect(execute('date', false)).to eql date
    end

    it 'should raise SystemCallError exception' do
      subject.should_receive(:capture3).with('unknown').and_return(['', error_message, failure])

      SUSE::Connect::GlobalLogger.instance.log.should_receive(:error)
      expect { execute('unknown') }.to raise_error(SUSE::Connect::SystemCallError, error_message)
    end

    it 'should raise ZypperError exception' do
      subject.should_receive(:capture3).with('zypper unknown').and_return(['', error_message, failure])

      SUSE::Connect::GlobalLogger.instance.log.should_receive(:error)
      expect { execute('zypper unknown') }.to raise_error(SUSE::Connect::ZypperError, error_message)
    end
  end

end
