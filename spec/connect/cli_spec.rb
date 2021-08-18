require 'spec_helper'
require 'suse/connect/cli'

describe SUSE::Connect::Cli do
  let(:default_logger) { SUSE::Connect::GlobalLogger.instance.log }
  let(:string_logger) { ::Logger.new(StringIO.new) }
  let(:opts) { {} }
  let(:cli) { described_class.new opts }
  let(:config_file) { File.expand_path File.join(File.dirname(__FILE__), '../fixtures/SUSEConnect') }

  before do
    allow_any_instance_of(SUSE::Connect::Config).to receive(:read).and_return({})
    allow(Zypper).to receive_messages(base_product: {})
    allow_any_instance_of(described_class).to receive_messages(puts: true)
    SUSE::Connect::GlobalLogger.instance.log = string_logger
    allow_any_instance_of(Status).to receive(:activated_base_product?).and_return(true)
  end

  after do
    SUSE::Connect::GlobalLogger.instance.log = default_logger
  end

  describe '#execute!' do
    subject { cli.execute! }

    context 'server errors' do
      let(:opts) { %w[-r 123] }

      it 'should produce log output if ApiError encountered' do
        expect(string_logger).to receive(:fatal).with("Error: Registration server returned 'test' (222)")
        response = Net::HTTPResponse.new('1.1', 222, 'Test')
        allow(response).to receive(:body).and_return('localized_error' => 'test')
        allow_any_instance_of(Client).to receive(:register!).and_raise ApiError.new(response)
        expect { cli.execute! }.to exit_with_code(67)
      end

      context 'system has proper credentials file' do
        it 'should suggest re-registration if ApiError 401 encountered' do
          response = Net::HTTPResponse.new('1.1', 401, 'Test')
          allow(System).to receive(:credentials?).and_return true
          expect_any_instance_of(Client).to receive(:register!).and_raise ApiError.new(response)
          expect(string_logger).to receive(:fatal).with(match(/Error: Invalid system credentials/))
          expect { cli.execute! }.to exit_with_code(67)
        end
      end

      context 'system has no proper credentials file' do
        it 'should suggest re-registration if ApiError 401 encountered' do
          # INFO: Use double instead of HTTPResponse mock https://www.ruby-forum.com/topic/4407036
          response = double(code: 401, body: { 'localized_error' => 'Invalid registration code' })
          allow(System).to receive(:credentials?).and_return false
          expect_any_instance_of(Client).to receive(:register!).and_raise ApiError.new(response)

          error_message = "Error: Registration server returned 'Invalid registration code' (401)"
          expect(string_logger).to receive(:fatal).with(error_message)
          expect { cli.execute! }.to exit_with_code(67)
        end
      end

      context 'when the system is managed by SUMA/Uyuni' do
        before do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(Cli::SUMA_SYSTEM_ID).and_return(true)
        end

        it 'will fail with an error message' do
          expect(string_logger).to receive(:error).with('This system is managed by SUSE Manager / Uyuni, do not use SUSEconnect.')
          expect { cli.execute! }.to exit_with_code(1)
        end
      end

      context 'while calling the obsolete RegistrationProxy' do
        it 'should suggest updating the Registration Proxy server' do
          expect_any_instance_of(Client).to receive(:register!).and_raise JSON::ParserError
          allow_any_instance_of(SUSE::Connect::Config).to receive(:url_default?).and_return(false)
          expect_any_instance_of(Api).to receive(:up_to_date?).and_return(false)

          error = "Your Registration Proxy server doesn't support this function. Please update it and try again."
          expect(string_logger).to receive(:fatal).with(error)

          expect { cli.execute! }.to exit_with_code(66)
        end
      end

      it 'should produce log output if connection refused' do
        expect(string_logger).to receive(:fatal).with('Error: Connection refused by server https://scc.suse.com')
        allow_any_instance_of(Client).to receive(:register!).and_raise Errno::ECONNREFUSED
        expect { cli.execute! }.to exit_with_code(64)
      end

      it 'should produce log output if json parse error encountered' do
        expect(string_logger).to receive(:fatal).with('Error: Cannot parse response from server')
        allow_any_instance_of(Client).to receive(:register!).and_raise JSON::ParserError
        expect { cli.execute! }.to exit_with_code(66)
      end

      it 'should produce log output if EACCES encountered' do
        expect(string_logger).to receive(:fatal).with('Error: Access error - Permission denied')
        allow_any_instance_of(Client).to receive(:register!).and_raise Errno::EACCES
        expect { cli.execute! }.to exit_with_code(65)
      end

      it 'should produce log output if FileError encountered' do
        expect(string_logger).to receive(:fatal).with('FileError: \'test\'')
        allow_any_instance_of(Client).to receive(:register!).and_raise(FileError, 'test')
        expect { cli.execute! }.to exit_with_code(68)
      end
    end

    context 'zypper error' do
      let(:opts) { %w[-r 456] }

      it 'should produce log output if zypper errors' do
        expect(string_logger).to receive(:fatal).with('Error: zypper returned (666) with \'<stream><error>zypper down</error></stream>\'')
        allow_any_instance_of(Client).to receive(:register!).and_raise ZypperError.new(666, '<stream><error>zypper down</error></stream>')
        expect { cli.execute! }.to raise_error(SystemExit)
      end
    end

    context 'parameter dependencies' do
      it 'requires no other parameters on --status' do
        cli = described_class.new(%w[--status])
        expect_any_instance_of(Status).to receive(:print_product_statuses)
        cli.execute!
      end

      it 'does not require --regcode or --url when specifying a product (eg. an extension)' do
        cli = described_class.new(%w[-p sle-module-web-scripting/12/x86_64])
        expect_any_instance_of(Client).to receive(:register!)
        cli.execute!
      end

      context 'when the system has no activated base product' do
        it 'shows a properly rendered help page' do
          expect_any_instance_of(Client).not_to receive(:register!)
          expect_any_instance_of(described_class).to receive(:puts) do |option_parser|
            expect(option_parser.instance_variable_get(:@opts).to_s.split("\n").map(&:length)).to all be <= 80
          end
          expect { cli.execute! }.to raise_error(SystemExit)
        end

        it 'registers the system if --regcode was provided' do
          cli = described_class.new(%w[-r 456])
          expect_any_instance_of(Client).to receive(:register!)
          cli.execute!
        end

        it 'registers the system if --url was provided' do
          cli = described_class.new(%w[--url http://somewhere.com])
          expect_any_instance_of(Client).to receive(:register!)
          expect_any_instance_of(SUSE::Connect::Config).to receive(:write!)
          cli.execute!
        end

        it 'registers the system if using a configured proxy' do
          allow_any_instance_of(SUSE::Connect::Config).to receive(:url_default?).and_return(false)
          expect_any_instance_of(Client).to receive(:register!)
          cli.execute!
        end
      end

      it 'requires either --regcode or --url (regcode-less SMT registration) but respects config attributes' do
        config = SUSE::Connect::Config.new(config_file)
        config.url = 'https://smt.server'
        allow(SUSE::Connect::Config).to receive(:new).and_return(config)

        allow_any_instance_of(Client).to receive(:register!).and_return true

        expect(string_logger).not_to receive(:error)
          .with('Please set the regcode parameter to register against SCC, or the url parameter to register against SMT')
        cli.execute!
      end

      it '--instance-data requires --url' do
        cli = described_class.new(%w[--instance-data /tmp/test])
        expect(string_logger).to receive(:error)
          .with('Please use --instance-data only in combination with --url pointing to your RMT or SMT server')
        expect { cli.execute! }.to raise_error(SystemExit)
      end

      it '--instance-data is mutually exclusive with --regcode' do
        cli = described_class.new(%w[-r 123 --instance-data /tmp/test --url test])
        expect(string_logger).to receive(:error)
          .with('Please use either --regcode or --instance-data')
        expect_any_instance_of(SUSE::Connect::Config).to receive(:write!)
        expect { cli.execute! }.to raise_error(SystemExit)
      end

      it '--url implies --write-config' do
        cli = described_class.new(%w[-r 123 --url http://foo.test.com])
        expect(cli.config.write_config).to eq true
        allow_any_instance_of(SUSE::Connect::Client).to receive(:register!)
        expect_any_instance_of(SUSE::Connect::Config).to receive(:write!)
        cli.execute!
      end

      it 'writes config even when exceptions are raised' do
        cli = described_class.new(%w[--url http://foo.test.com])
        expect(cli.config.write_config).to eq true

        response = double(code: 401, body: { 'localized_error' => 'Invalid foo' })
        allow(System).to receive(:credentials?).and_return true
        allow_any_instance_of(SUSE::Connect::Client).to receive(:register!).and_raise(ApiError.new(response))

        expect_any_instance_of(SUSE::Connect::Config).to receive(:write!)
        expect { cli.execute! }.to raise_error(SystemExit)
      end
    end

    describe 'de-register command' do
      let(:opts) { %w[--de-register] }

      it '--de-register calls deregister! method' do
        expect_any_instance_of(Client).to receive(:deregister!)
        subject
      end

      context 'on unregistered system' do
        before { allow(SUSE::Connect::System).to receive(:credentials).and_return(nil) }

        it 'dies with error' do
          expect(string_logger).to receive(:fatal).with(/Deregistration failed. Check if the system has been registered/)
          expect { subject }.to exit_with_code(69)
        end
      end

      context 'with product specified' do
        let(:opts) { %w[--de-register -p foo/12/x86_64] }
        before { allow(SUSE::Connect::System).to receive(:credentials?).and_return(true) }

        context 'calling for base product' do
          before do
            allow(Zypper).to receive(:base_product).and_return SUSE::Connect::Zypper::Product.new(name: 'foo', version: '12', arch: 'x86_64')
          end

          it 'dies with error' do
            expect(string_logger).to receive(:fatal).with(/Can not deregister base product/)
            expect { subject }.to exit_with_code(70)
          end
        end
      end
    end

    context 'cleanup command' do
      it '--cleanup calls Systems cleanup! method' do
        cli = described_class.new(%w[--cleanup])
        expect(System).to receive(:cleanup!)
        cli.execute!
      end
    end

    context '--namespace option' do
      it 'requires a namespace' do
        expect(string_logger).to receive(:error).with('Please provide a namespace')
        expect { described_class.new('--namespace') }.to exit_with_code(1)
      end

      it 'sets the given namespace in the config' do
        cli = described_class.new(%w[--namespace mynamespace])
        expect(cli.config[:namespace]).to eq 'mynamespace'
      end

      it 'automatically writes the config' do
        cli = described_class.new(%w[--namespace mynamespace])
        expect(cli.options[:write_config]).to be true
      end
    end

    context 'status subcommand' do
      it '--status calls json_product_status' do
        cli = described_class.new(%w[--status])
        expect_any_instance_of(Client).to_not receive(:register!)
        expect_any_instance_of(Status).to receive(:json_product_status)
        cli.execute!
      end

      it '--status-text calls text_product_status' do
        cli = described_class.new(%w[--status-text])
        expect_any_instance_of(Client).to_not receive(:register!)
        expect_any_instance_of(Status).to receive(:text_product_status)
        cli.execute!
      end
    end

    describe 'list extensions subcommand' do
      context 'on system with registered base product' do
        it '--list-extensions lists all available extensions on the system' do
          cli = described_class.new(%w[--list-extensions])
          expect_any_instance_of(Client).not_to receive(:register!)
          expect_any_instance_of(Status).to receive(:print_extensions_list)
          cli.execute!
        end
      end

      context 'on system with no registered base product' do
        it '--list-extensions exits with an error explaining that a base product has to be registered first' do
          allow_any_instance_of(Status).to receive(:activated_base_product?).and_return(false)
          cli = described_class.new(%w[--list-extensions])
          expect_any_instance_of(Client).not_to receive(:register!)
          expect_any_instance_of(Status).not_to receive(:print_extensions_list)
          expect(string_logger).to receive(:error)
            .with(/To list extensions, you must first register the base product, using: SUSEConnect -r <registration code>/)
          expect_any_instance_of(described_class).to receive(:exit)
          cli.execute!
        end
      end
    end

    context 'rollback subcommand' do
      it '--rollback calls SUSE::Connect::Migration.rollback' do
        cli = described_class.new(%w[--rollback])
        expect_any_instance_of(Client).not_to receive(:register!)
        expect(Migration).to receive(:rollback)
        expect { cli.execute! }.not_to exit_with_code(1)
      end
    end

    describe 'config write' do
      it 'writes config if appropriate cli param been passed' do
        cli = described_class.new(%w[--write-config --status])
        expect_any_instance_of(SUSE::Connect::Config).to receive(:write!)
        allow_any_instance_of(Status).to receive(:print_product_statuses)
        cli.execute!
      end
    end
  end

  describe '?extract_options' do
    it 'sets token options' do
      argv = %w[-r matoken]
      cli = described_class.new(argv)
      expect(cli.options[:token]).to eq 'matoken'
    end

    it 'sets product options' do
      argv = %w[--product sles/12/i386]
      cli = described_class.new(argv)
      expect(cli.options[:product]).to eq Remote::Product.new(identifier: 'sles', version: '12', arch: 'i386')
    end

    it 'sets token options' do
      argv = %w[--regcode matoken]
      cli = described_class.new(argv)
      expect(cli.options[:token]).to eq 'matoken'
    end

    it 'sets email options' do
      argv = %w[--email me@hotmail.com]
      cli = described_class.new(argv)
      expect(cli.options[:email]).to eq 'me@hotmail.com'
    end

    it 'sets url options' do
      argv = %w[--url test]
      cli = described_class.new(argv)
      expect(cli.options[:url]).to eq 'test'
    end

    it 'puts version on version flag' do
      argv = %w[--version]
      expect_any_instance_of(described_class).to receive(:puts).with(VERSION)
      expect { described_class.new(argv) }.to exit_with_code(0)
    end

    it 'outputs help on help flag with no line longer than 80 characters' do
      argv = %w[--help]
      expect_any_instance_of(described_class).to receive(:puts) do |option_parser|
        expect(option_parser.instance_variable_get(:@opts).to_s.split("\n").map(&:length)).to all be <= 80
      end
      expect { described_class.new(argv) }.to exit_with_code(0)
    end

    it 'sets verbose options' do
      argv = %w[--debug]
      cli = described_class.new(argv)
      expect(cli.options[:debug]).to be true
    end

    it 'sets deregister option' do
      argv = %w[--de-register]
      cli = described_class.new(argv)
      expect(cli.options[:deregister]).to be true
    end

    it 'sets root option' do
      argv = %w[--root /path/to/root]
      described_class.new(argv)
      expect(SUSE::Connect::System.filesystem_root).to eq '/path/to/root'
      SUSE::Connect::System.filesystem_root = nil
    end

    it 'requests status sub-command' do
      argv = %w[--status]
      expect(described_class.new(argv).options[:status]).to be true
    end

    it 'sets write_config option' do
      argv = %w[--write-config]
      cli = described_class.new(argv)
      expect(cli.options[:write_config]).to be true
    end
  end

  describe 'errors on invalid options format' do
    it 'error on invalid product options format with hint where to find correct product identifiers' do
      expect(string_logger).to receive(:error).with(/Please provide the product identifier in this format.*SUSEConnect --list-extensions/)
      argv = %w[--product sles]
      expect { described_class.new(argv) }.to exit_with_code(1)
    end
  end

  describe '?check_if_param' do
    it 'will exit with message if opt is nil' do
      expect_any_instance_of(described_class).to receive(:exit)
      expect(string_logger).to receive(:error).with('Kaboom')
      cli.send(:check_if_param, nil, 'Kaboom')
    end
  end

  describe 'reads environment variables' do
    before { ENV['LANG'] = 'de' }

    it 'sets language header based on LANG' do
      expect(cli.options[:language]).to eq 'de'
    end
  end
end
