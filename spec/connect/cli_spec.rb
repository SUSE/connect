require 'spec_helper'
require 'suse/connect/cli'

describe SUSE::Connect::Cli do

  subject { SUSE::Connect::Cli }

  let(:default_logger) { SUSE::Connect::GlobalLogger.instance.log }
  let(:string_logger) { ::Logger.new(StringIO.new) }
  let(:cli) { subject.new({}) }
  let(:config_file) { File.expand_path File.join(File.dirname(__FILE__), '../fixtures/SUSEConnect') }

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

    context 'server errors' do

      let(:cli) { subject.new(%w{-r 123}) }

      it 'should produce log output if ApiError encountered' do
        string_logger.should_receive(:fatal).with("Error: SCC returned 'test' (222)")
        response = Net::HTTPResponse.new('1.1', 222, 'Test')
        expect(response).to receive(:body).and_return('localized_error' => 'test')
        Client.any_instance.stub(:register!).and_raise ApiError.new(response)
        cli.execute!
      end

      it 'should suggest re-registration if ApiError 401 encountered' do
        response = Net::HTTPResponse.new('1.1', 401, 'Test')
        expect_any_instance_of(Client).to receive(:register!).and_raise ApiError.new(response)
        expect(string_logger).to receive(:fatal).with(match(/Error: Not authorised./))
        cli.execute!
      end

      it 'should produce log output if connection refused' do
        string_logger.should_receive(:fatal).with('Error: Connection refused by server https://scc.suse.com')
        Client.any_instance.stub(:register!).and_raise Errno::ECONNREFUSED
        cli.execute!
      end

      it 'should produce log output if json parse error encountered' do
        string_logger.should_receive(:fatal).with('Error: Cannot parse response from server')
        Client.any_instance.stub(:register!).and_raise JSON::ParserError
        cli.execute!
      end

      it 'should produce log output if EACCES encountered' do
        string_logger.should_receive(:fatal).with('Error: Access error - Permission denied')
        Client.any_instance.stub(:register!).and_raise Errno::EACCES
        cli.execute!
      end

      it 'should produce log output if FileError encountered' do
        string_logger.should_receive(:fatal).with('FileError: \'test\'')
        Client.any_instance.stub(:register!).and_raise(FileError, 'test')
        cli.execute!
      end

    end

    context 'zypper error' do

      let(:cli) { subject.new(%w{-r 456}) }

      it 'should produce log output if zypper errors' do
        string_logger.should_receive(:fatal).with('Error: zypper returned (666) with \'<stream><error>zypper down</error></stream>\'')
        Client.any_instance.stub(:register!).and_raise ZypperError.new(666, '<stream><error>zypper down</error></stream>')
        cli.execute!
      end

    end

    context 'parameter dependencies' do

      it 'requires no other parameters on --status' do
        cli = subject.new(%w{--status})
        expect_any_instance_of(Status).to receive(:print_product_statuses)
        cli.execute!
      end

      it 'requires either --token or --url (regcode-less SMT registration)' do
        string_logger.should_receive(:error)
          .with('Please set the regcode parameter to register against SCC, or the url parameter to register against SMT')
        cli.execute!
      end

      it 'requires either --token or --url (regcode-less SMT registration) but respects config attributes' do
        config = SUSE::Connect::Config.new(config_file)
        config.url = 'https://smt.server'
        allow(SUSE::Connect::Config).to receive(:new).and_return(config)

        Client.any_instance.stub(:register!).and_return true

        string_logger.should_not_receive(:error)
          .with('Please set the regcode parameter to register against SCC, or the url parameter to register against SMT')
        cli.execute!
      end

      it '--instance-data requires --url' do
        cli = subject.new(%w{--instance-data /tmp/test})
        string_logger.should_receive(:error)
          .with('Please use --instance-data only in combination with --url pointing to your SMT server')
        cli.execute!
      end

      it '--instance-data is mutually exclusive with --token' do
        cli = subject.new(%w{-r 123 --instance-data /tmp/test --url test})
        string_logger.should_receive(:error)
          .with('Please use either --token or --instance-data')
        cli.execute!
      end

    end

    context 'status subcommand' do

      it '--status calls json_product_status' do
        cli = subject.new(%w{--status})
        expect_any_instance_of(Client).to_not receive(:register!)
        expect_any_instance_of(Status).to receive(:json_product_status)
        cli.execute!
      end

      it '--status-text calls text_product_status' do
        cli = subject.new(%w{--status-text})
        expect_any_instance_of(Client).to_not receive(:register!)
        expect_any_instance_of(Status).to receive(:text_product_status)
        cli.execute!
      end

    end

    describe 'config write' do

      it 'writes config if approproate cli param been passed' do
        cli = subject.new(%w{--write-config --status})
        expect_any_instance_of(Config).to receive(:write!)
        allow_any_instance_of(Status).to receive(:print_product_statuses)
        cli.execute!
      end

    end

  end

  describe '?extract_options' do

    it 'sets token options' do
      argv = %w{-r matoken}
      cli = subject.new(argv)
      cli.options[:token].should eq 'matoken'
    end

    it 'sets product options' do
      argv = %w{--product sles/12/i386}
      cli = subject.new(argv)
      cli.options[:product].should eq Remote::Product.new(:identifier => 'sles', :version => '12', :arch => 'i386')
    end

    it 'sets token options' do
      argv = %w{--regcode matoken}
      cli = subject.new(argv)
      cli.options[:token].should eq 'matoken'
    end

    it 'sets email options' do
      argv = %w{--email me@hotmail.com}
      cli = subject.new(argv)
      cli.options[:email].should eq 'me@hotmail.com'
    end

    it 'sets url options' do
      argv = %w{--url test}
      cli = subject.new(argv)
      cli.options[:url].should eq 'test'
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
      cli.options[:debug].should be true
    end

    it 'sets root option' do
      argv = %w{--root /path/to/root}
      subject.new(argv)
      SUSE::Connect::System.filesystem_root.should eq '/path/to/root'
      SUSE::Connect::System.filesystem_root = nil
    end

    it 'requests status sub-command' do
      argv = %w{--status}
      expect(subject.new(argv).options[:status]).to be true
    end

    it 'sets write_config option' do
      argv = %w{--write-config}
      cli = subject.new(argv)
      cli.options[:write_config].should be true
    end

  end

  describe 'errors on invalid options format' do

    it 'error on invalid product options format' do
      string_logger.should_receive(:error).with(/Please provide the product identifier in this format/)
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

  describe 'reads environment variables' do
    it 'sets language header based on LANG' do
      # is ENV global?
      ENV['LANG'] = 'de'
      cli = subject.new([])
      expect(cli.options[:language]).to eq 'de'
    end

  end

end
