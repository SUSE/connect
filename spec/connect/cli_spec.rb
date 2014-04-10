require 'spec_helper'
require 'suse/connect/cli'
require 'stringio'

describe SUSE::Connect::Cli do

  subject { SUSE::Connect::Cli }

  describe '#execute!' do
    let(:default_logger) { SUSE::Connect::GlobalLogger.instance.log }
    let(:string_logger) { ::Logger.new(StringIO.new) }
    let(:cli) { subject.new({}) }

    before do
      cli.stub(:exit => true)
      SUSE::Connect::GlobalLogger.instance.log = string_logger
    end

    after do
      SUSE::Connect::GlobalLogger.instance.log = default_logger
    end

    it 'should produce log output if ApiError encountered' do
      string_logger.should_receive(:error).with('ApiError with response: {:test=>1} Code: 222')
      Client.any_instance.stub(:register!).and_raise ApiError.new(222, :test => 1)
      cli.execute!
    end

    it 'should produce log output if ApiError encountered' do
      string_logger.should_receive(:error).with('connection refused by server')
      Client.any_instance.stub(:register!).and_raise Errno::ECONNREFUSED
      cli.execute!
    end

    it 'should produce log output if ApiError encountered' do
      string_logger.should_receive(:error).with('cannot parse response from server')
      Client.any_instance.stub(:register!).and_raise JSON::ParserError
      cli.execute!
    end

    it 'should produce log output if EACCES encountered' do
      string_logger.should_receive(:error).with('access error - cannot create required folder/file')
      Client.any_instance.stub(:register!).and_raise Errno::EACCES
      cli.execute!
    end

  end

  describe '?extract_options' do

    before do
      Object.send(:remove_const, :ARGV)
      subject.any_instance.stub(:exit)
    end

    it 'sets token options' do
      ARGV = %w{-r matoken}
      cli = subject.new(ARGV)
      cli.options[:token].should eq 'matoken'
    end

    it 'sets token options' do
      ARGV = %w{--regcode matoken}
      cli = subject.new(ARGV)
      cli.options[:token].should eq 'matoken'
    end

    it 'sets insecure options' do
      ARGV = %w{--insecure}
      cli = subject.new(ARGV)
      cli.options[:insecure].should be_true
    end

    it 'sets url options' do
      ARGV = %w{--url test}
      cli = subject.new(ARGV)
      cli.options[:url].should eq 'test'
    end

    it 'sets insecure options' do
      ARGV = %w{-d}
      cli = subject.new(ARGV)
      cli.options[:dry].should be_true
    end

    it 'puts version on version flag' do
      ARGV = %w{--version}
      subject.any_instance.should_receive(:puts).with(VERSION)
      subject.new(ARGV)
    end

    it 'output help on help flag' do
      ARGV = %w{--help}
      subject.any_instance.should_receive(:puts)
      subject.new(ARGV)
    end

    it 'sets verbose option' do
      ARGV = %w{-v}
      cli = subject.new(ARGV)
      cli.options[:verbose].should be_true
    end

    it 'sets root option' do
      ARGV = %w{--root /path/to/root}
      subject.new(ARGV)
      $root.should eq '/path/to/root'
      $root = nil
    end

  end

  describe '?check_if_param' do
    it 'will exit with message if opt is nil' do
      subject.any_instance.should_receive(:exit)
      subject.any_instance.should_receive(:puts).with 'Kaboom'
      subject.new({}).send(:check_if_param, nil, 'Kaboom')
    end
  end

end
