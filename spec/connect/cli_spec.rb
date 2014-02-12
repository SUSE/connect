require 'spec_helper'
require 'suse/connect/cli'

describe SUSE::Connect::Cli do

  subject { SUSE::Connect::Cli }

  describe '#execute!' do

    it 'should produce log output if no token provided' do
      Logger.should_receive(:error).with('no registration token provided')
      Client.any_instance.stub(:execute!).and_raise CannotBuildTokenAuth
      cli = subject.new({})
      cli.stub(:exit => true)
      cli.execute!
    end

    it 'should produce log output if ApiError encountered' do
      Logger.should_receive(:error).with('ApiError with response: {:test=>1} Code: 222')
      Client.any_instance.stub(:execute!).and_raise ApiError.new(222, :test => 1)
      cli = subject.new({})
      cli.stub(:exit => true)
      cli.execute!
    end

    it 'should produce log output if ApiError encountered' do
      Logger.should_receive(:error).with('connection refused by server')
      Client.any_instance.stub(:execute!).and_raise Errno::ECONNREFUSED
      cli = subject.new({})
      cli.stub(:exit => true)
      cli.execute!
    end

    it 'should produce log output if ApiError encountered' do
      Logger.should_receive(:error).with('cannot parse response from server')
      Client.any_instance.stub(:execute!).and_raise JSON::ParserError
      cli = subject.new({})
      cli.stub(:exit => true)
      cli.execute!
    end

    it 'should produce log output if EACCES encountered' do
      Logger.should_receive(:error).with('access error - cannot create required folder/file')
      Client.any_instance.stub(:execute!).and_raise Errno::EACCES
      cli = subject.new({})
      cli.stub(:exit => true)
      cli.execute!
    end

    it 'should output help if nothing passed to bin' do
      Client.any_instance.stub(:execute!).and_raise TokenNotPresent
      cli = subject.new({})
      cli.stub(:exit => true)
      cli.should_receive(:puts).with kind_of(OptionParser)
      cli.execute!
    end

  end

  describe '?extract_options' do

    before do
      Object.send(:remove_const, :ARGV)
      subject.any_instance.stub(:exit)
    end

    it 'sets token options' do
      ARGV = %w{-t matoken}
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

    it 'sets verbopse options' do
      ARGV = %w{-v}
      cli = subject.new(ARGV)
      cli.options[:verbose].should be_true
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
