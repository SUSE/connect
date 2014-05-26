require 'spec_helper'
require 'suse/connect/cli'
require 'stringio'

describe SUSE::Connect::Cli do

  subject { SUSE::Connect::Cli }
  let(:default_logger) { SUSE::Connect::GlobalLogger.instance.log }
  let(:string_logger) { ::Logger.new(StringIO.new) }
  let(:cli) { subject.new({}) }

  before do
    Zypper.stub(:base_product => {})
    subject.any_instance.stub(:exit)
    subject.any_instance.stub(:puts => true)
    SUSE::Connect::GlobalLogger.instance.log = string_logger
  end

  after do
    SUSE::Connect::GlobalLogger.instance.log = default_logger
  end

  describe '#execute!' do

    it 'should produce log output if ApiError encountered' do
      string_logger.should_receive(:error).with("Error: SCC returned 'test' (222)")
      response = Net::HTTPResponse.new('1.1', 222, 'Test')
      expect(response).to receive(:body).and_return('localized_error' => 'test')
      Client.any_instance.stub(:register!).and_raise ApiError.new(response)
      cli.execute!
    end

    it 'should produce log output if ApiError encountered' do
      string_logger.should_receive(:error).with('Error: Connection refused by server')
      Client.any_instance.stub(:register!).and_raise Errno::ECONNREFUSED
      cli.execute!
    end

    it 'should produce log output if ApiError encountered' do
      string_logger.should_receive(:error).with('Error: Cannot parse response from server')
      Client.any_instance.stub(:register!).and_raise JSON::ParserError
      cli.execute!
    end

    it 'should produce log output if EACCES encountered' do
      string_logger.should_receive(:error).with('Error: Access error - Permission denied')
      Client.any_instance.stub(:register!).and_raise Errno::EACCES
      cli.execute!
    end

  end

  describe '?extract_options' do

    it 'sets token options' do
      argv = %w{-r matoken}
      cli = subject.new(argv)
      cli.options[:token].should eq 'matoken'
    end

    it 'sets product options' do
      argv = %w{--product sles-12-i386}
      cli = subject.new(argv)
      cli.options[:product].should eq(:name => 'sles', :version => '12', :arch => 'i386')
    end

    it 'sets token options' do
      argv = %w{--regcode matoken}
      cli = subject.new(argv)
      cli.options[:token].should eq 'matoken'
    end

    it 'sets insecure options' do
      argv = %w{--insecure}
      cli = subject.new(argv)
      cli.options[:insecure].should be_true
    end

    it 'sets url options' do
      argv = %w{--url test}
      cli = subject.new(argv)
      cli.options[:url].should eq 'test'
    end

    it 'sets insecure options' do
      argv = %w{-d}
      cli = subject.new(argv)
      cli.options[:dry].should be_true
    end

    it 'sets language options' do
      argv = %w{-l de}
      cli = subject.new(argv)
      cli.options[:language].should eq 'de'
    end

    it 'puts version on version flag' do
      argv = %w{--version}
      subject.any_instance.should_receive(:puts).with(VERSION)
      subject.new(argv)
    end

    it 'output help on help flag' do
      argv = %w{--help}
      subject.any_instance.should_receive(:puts)
      subject.new(argv)
    end

    it 'sets verbose options' do
      argv = %w{--debug}
      cli = subject.new(argv)
      cli.options[:debug].should be_true
    end

    it 'sets root option' do
      argv = %w{--root /path/to/root}
      subject.new(argv)
      SUSE::Connect::System.filesystem_root.should eq '/path/to/root'
      SUSE::Connect::System.filesystem_root = ''
    end

  end

  describe 'errors on invalid options' do

    it 'error on invalid product options format' do
      string_logger.should_receive(:error) do |msg|
        msg =~ /Please provide the product identifier in this format:/
      end
      argv = %w{--product sles}
      subject.new(argv)
    end

  end

  describe '?check_if_param' do
    it 'will exit with message if opt is nil' do
      subject.any_instance.should_receive(:exit)
      string_logger.should_receive(:error).with('Kaboom')
      subject.new({}).send(:check_if_param, nil, 'Kaboom')
    end
  end

end
