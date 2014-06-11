require 'spec_helper'
require 'suse/toolkit/system_calls'

describe SUSE::Toolkit::SystemCalls do

  subject { Zypper }

  before do
    subject.send(:include, SUSE::Toolkit::SystemCalls)
  end

  describe '.call' do

    it 'should make a system call' do
      subject.should_receive(:system).with('date').and_return(true)
      subject.send(:call, 'date').should be true
    end

    it 'should produce log output if call failed' do
      subject.should_receive(:system).with('date').and_return(false)
      SUSE::Connect::GlobalLogger.instance.log.should_receive(:error)
      subject.send(:call, 'date')
    end

  end

  describe '.call_with_output' do

    it 'should make a system call and return output from system' do
      subject.should_receive(:'`').with('date').and_return("Thu Mar 13 12:22:51 CET 2014\n")
      subject.send(:call_with_output, 'date')
    end

  end

end
