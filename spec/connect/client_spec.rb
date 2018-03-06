require 'spec_helper'

describe SUSE::Connect::Client do
  let(:config) { SUSE::Connect::Config.new }
  let(:default_logger) { SUSE::Connect::GlobalLogger.instance.log }
  let(:string_logger) { ::Logger.new(StringIO.new) }
  let(:client_instance) { described_class.new config }

  let(:product_tree) { JSON.parse(File.read('spec/fixtures/product_tree.json')) }
  let(:product) { Remote::Product.new(product_tree) }

  let(:submodule) { product.extensions[1] }
  let(:subsubmodule) { product.extensions[1].extensions[1] }

  subject { client_instance }

  describe '.new' do
    context 'empty opts' do
      it 'should set url to default_url' do
        expect(subject.config.url).to eq SUSE::Connect::Config::DEFAULT_URL
      end
    end

    context 'passed opts' do
      it 'should set insecure flag from options if it was passed via constructor' do
        config.insecure = true
        client = Client.new(config)
        expect(client.config.insecure).to be true
      end

      it 'should set write_config flag from options if it was passed via constructor' do
        config.write_config = true
        client = Client.new(config)
        expect(client.config.write_config).to be true
      end

      it 'allows to pass arbitrary options' do
        config.foo = 'bar'
        client = Client.new(config)
        expect(client.config.foo).to eq 'bar'
      end
    end

    context 'from config' do
      subject do
        SUSE::Connect::Client.new(SUSE::Connect::Config.new)
      end

      before do
        allow_any_instance_of(SUSE::Connect::Config).to receive(:read).and_return(
          'url'      => 'https://localsmt.domain.local',
          'language' => 'RU',
          'insecure' => true
        )
      end

      it 'should set url to the config URL' do
        expect(subject.config.url).to eq 'https://localsmt.domain.local'
      end

      it 'should set token to one from config file' do
        expect(subject.config.insecure).to eq true
      end

      it 'should set language to one from config file' do
        expect(subject.config.language).to eq 'RU'
      end
    end
  end

  describe '#announce_system' do
    context 'direct connection' do
      subject do
        config.token = 'blabla'
        SUSE::Connect::Client.new(config)
      end

      before do
        api_response = double('api_response')
        allow(api_response).to receive_messages(body: { 'login' => 'lg', 'password' => 'pw' })
        allow_any_instance_of(Api).to receive_messages(announce_system: api_response)
        allow(subject).to receive_messages(token_auth: 'auth')
      end

      it 'calls underlying api' do
        allow(Zypper).to receive :write_base_credentials
        expect_any_instance_of(Api).to receive :announce_system
        subject.announce_system
      end

      it 'forwards the optional parameter "distro_target" to the API' do
        optional_target = 'optional_target'
        expect_any_instance_of(Api).to receive(:announce_system).with('auth', optional_target, nil)
        subject.announce_system(optional_target)
      end

      it 'forwards the optional parameter "namespace" to the API' do
        optional_namespace = 'namespace'
        expect_any_instance_of(Api).to receive(:announce_system).with('auth', optional_namespace, nil)
        subject.announce_system(optional_namespace)
      end

      it 'reads instance_data_file and passes content the API' do
        instance_file_path = 'spec/fixtures/instance_data.xml'
        expect_any_instance_of(Api).to receive(:announce_system).with('auth', nil, File.read(instance_file_path))
        subject.announce_system(nil, instance_file_path)
      end

      it 'fails on unavailable instance_data_file' do
        expect(File).to receive(:readable?).with('/test').and_return(false)
        expect { subject.announce_system(nil, '/test') }.to raise_error(FileError, 'File not found')
      end
    end

    describe '#update_system' do
      context 'direct connection' do
        subject { SUSE::Connect::Client.new(config) }

        before do
          allow(subject).to receive_messages(system_auth: 'auth')
          allow_any_instance_of(Api).to receive(:update_system)
        end

        it 'calls underlying api' do
          expect_any_instance_of(Api).to receive(:update_system).with('auth', nil, nil)
          subject.update_system
        end

        it 'forwards distro_target to api' do
          expect_any_instance_of(Api).to receive(:update_system).with('auth', 'my-distro-target', nil)
          subject.update_system('my-distro-target')
        end

        it 'forwards the optional parameter "namespace" to the API' do
          optional_namespace = 'namespace'
          expect_any_instance_of(Api).to receive(:update_system).with('auth', optional_namespace, nil)

          subject.update_system(optional_namespace)
        end

        it 'forwards instance_data_file to api' do
          expect(System).to receive(:read_file).with('filepath').and_return('')
          expect_any_instance_of(Api).to receive(:update_system).with('auth', 'my-distro-target', '')
          subject.update_system('my-distro-target', 'filepath')
        end
      end
    end

    context 'registration proxy connection' do
      subject do
        config.url = 'http://smt.local'
        SUSE::Connect::Client.new(config)
      end

      before do
        api_response = double('api_response')
        allow(api_response).to receive_messages(body: { 'login' => 'lg', 'password' => 'pw' })
        allow(Zypper).to receive(:write_base_credentials).with('lg', 'pw')
        allow_any_instance_of(Api).to receive_messages(announce_system: api_response)
        allow(subject).to receive_messages(token_auth: true)
      end

      it 'not raising exception if regcode is absent' do
        expect { subject.announce_system }.not_to raise_error
      end

      it 'calls underlying api' do
        allow(Zypper).to receive :write_base_credentials
        expect_any_instance_of(Api).to receive :announce_system
        subject.announce_system
      end
    end
  end

  describe '#activate_product' do
    let!(:stubbed_request) do
      stub_request(:post, 'https://scc.suse.com/connect/systems/products')
        .to_return status: 200, body: '{"name":"kinkat","url":"kinkaturl","product":{}}'
    end
    before { allow(client_instance).to receive_messages system_auth: 'secretsecret' }

    subject { client_instance.activate_product product }

    its(:name) { is_expected.to eq 'kinkat' }
    its(:url) { is_expected.to eq 'kinkaturl' }
    it { is_expected.to be_a SUSE::Connect::Remote::Service }

    it 'gets login and password from system' do
      expect(client_instance).to receive(:system_auth)
      subject
    end

    context 'when called' do
      before { subject }
      it { expect(stubbed_request).to have_been_made }

      context 'with email parameter' do
        subject { client_instance.activate_product product, 'email@domain.com' }
        it { expect(stubbed_request).to have_been_made }
      end
    end
  end

  describe '#deactivate_product' do
    let!(:stubbed_request) do
      stub_request(:delete, 'https://scc.suse.com/connect/systems/products')
        .to_return status: 200, body: '{"name":"kinkat","url":"kinkaturl","product":{}}'
    end
    before { allow(client_instance).to receive_messages system_auth: 'secretsecret' }

    subject { client_instance.deactivate_product product }

    its(:name) { is_expected.to eq 'kinkat' }
    its(:url) { is_expected.to eq 'kinkaturl' }
    it { is_expected.to be_a SUSE::Connect::Remote::Service }

    it 'gets login and password from system' do
      expect(client_instance).to receive(:system_auth)
      subject
    end

    context 'when called' do
      before { subject }
      it { expect(stubbed_request).to have_been_made }
    end
  end

  describe '#upgrade_product' do
    let(:product_ident) { { identifier: 'SLES', version: '12', arch: 'x86_64' } }

    before do
      api_response = double('api_response')
      allow(api_response).to receive_messages(body: { 'name' => 'tongobongo', 'url' => 'tongobongourl', 'product' => {} })
      allow_any_instance_of(Api).to receive_messages(upgrade_product: api_response)
      allow(subject).to receive_messages(system_auth: 'secretsecret')
    end

    it 'gets login and password from system' do
      expect(subject).to receive(:system_auth)
      subject.upgrade_product(product_ident)
    end

    it 'calls underlying api with proper parameters' do
      expect_any_instance_of(Api).to receive(:upgrade_product).with('secretsecret', product_ident)
      subject.upgrade_product(product_ident)
    end

    it 'returns service object' do
      service = subject.upgrade_product(product_ident)
      expect(service.name).to eq 'tongobongo'
      expect(service.url).to eq 'tongobongourl'
    end
  end

  describe '#downgrade_product' do
    it 'is an alias method for upgrade_product' do
      expect(subject).to respond_to(:downgrade_product)
    end
  end

  describe '#synchronize' do
    let(:products) { [{ identifier: 'SLES', version: '12', arch: 'x86_64' }] }
    let(:system_auth) { 'secretsecret' }

    before do
      allow_any_instance_of(Api).to receive(:synchronize).and_return(OpenStruct.new(body: {}))
    end

    it 'calls underlying api with proper parameters' do
      expect(subject).to receive(:system_auth).and_return system_auth
      expect_any_instance_of(Api).to receive(:synchronize).with(system_auth, products)
      subject.synchronize(products)
    end
  end

  describe '#register!' do
    before do
      allow(Zypper).to receive(:base_product).and_return product
      allow(Zypper).to receive(:write_base_credentials)

      allow_any_instance_of(Credentials).to receive(:write)
      allow(System).to receive_messages(credentials?: false)

      allow(subject).to receive(:show_product).and_return product
      allow(subject).to receive(:register_product).and_return true
      allow(subject).to receive(:print_title)
    end

    it 'should call announce if system not registered' do
      expect(subject).to receive(:announce_system)
      subject.register!
    end

    it 'should not call announce but update on api if system registered' do
      allow(System).to receive_messages(credentials?: true)
      expect(subject).not_to receive(:announce_system)
      expect(subject).to receive(:update_system)
      subject.register!
    end

    it 'should call register_product for the base product' do
      expect(subject).to receive(:announce_system)
      expect(subject).to receive(:register_product).with(product, install_release_package: false)
      subject.register!
    end

    it 'should call register_product for all recommended extensions of base module' do
      expect(subject).to receive(:announce_system)
      expect(subject).to receive(:register_product)
      expect(subject).to receive(:register_recommended!).with(submodule)
      subject.register!
    end

    it 'writes credentials file' do
      allow(System).to receive_messages(credentials?: false)
      allow(subject).to receive_messages(announce_system: %w[lg pw])
      expect(Credentials).to receive(:new).with('lg', 'pw', Credentials::GLOBAL_CREDENTIALS_FILE).and_call_original
      subject.register!
    end

    it 'prints message on successful activation' do
      expect(subject).to receive(:announce_system)
      expect(subject).to receive(:register_product).exactly(3).times
      expect(subject).to receive(:print_title).with('=> Activation successful!')
      subject.register!
    end
  end

  describe '#register_recommended!' do
    let(:not_recommended) { submodule.extensions[0] }

    it 'should activate the given extension' do
      expect(subject).to receive(:register_product).with(subsubmodule)
      expect(subject).not_to receive(:register_product).with(not_recommended)
      subject.register_recommended!(submodule)
    end
  end

  describe '#register_product' do
    let(:service_stub) { 'service_stub' }
    let(:fake_email) { 'email@email.org.what.ever' }

    let(:activate_str) { "\e[34m\e[1mActivating #{product.identifier} #{product.version}\e[0m" }

    let(:add_service_str) { "  \e[32m::\e[0m Adding zypper service..." }
    let(:install_pkg_str) { "  \e[32m::\e[0m Installing release package..." }

    before do
      config.email = fake_email
      SUSE::Connect::GlobalLogger.instance.log = string_logger
    end

    after do
      SUSE::Connect::GlobalLogger.instance.log = default_logger
    end

    it 'should activate the product, add service file and install release package' do
      expect(subject).to receive(:activate_product).with(product, fake_email).and_return service_stub
      expect(System).to receive(:add_service).with(service_stub)

      expect(Zypper).to receive(:refresh_services)
      expect(Zypper).to receive(:install_release_package).with(product.identifier)

      subject.register_product(product)
    end

    it 'should not install the release package if install_release_package is false' do
      expect(subject).to receive(:activate_product).with(product, fake_email).and_return service_stub
      expect(System).to receive(:add_service).with(service_stub)

      expect(Zypper).not_to receive(:refresh_services)
      expect(Zypper).not_to receive(:install_release_package)

      subject.register_product(product, false)
    end

    it 'informs the user about progress' do
      allow(subject).to receive(:activate_product)
      allow(System).to receive(:add_service)
      allow(Zypper).to receive(:refresh_services)
      allow(Zypper).to receive(:install_release_package)

      expect(string_logger).to receive(:info).with(activate_str)
      expect(string_logger).to receive(:info).with(add_service_str)
      expect(string_logger).to receive(:info).with(install_pkg_str)

      subject.register_product(product)
    end
  end

  describe '#show_product' do
    let(:stubbed_response) do
      OpenStruct.new(
        code: 200,
        body: { 'name' => 'short_name', 'identifier' => 'text_identifier' },
        success: true
      )
    end

    let(:product) { Remote::Product.new(identifier: 'text_identifier') }

    before do
      allow(subject).to receive_messages(system_auth: 'Basic: encodedstring')
    end

    it 'collects data from api response' do
      expect(subject.api).to receive(:show_product).with('Basic: encodedstring', product).and_return stubbed_response
      subject.show_product(product)
    end

    it 'returns array of extension products returned from api' do
      expect(subject.api).to receive(:show_product).with('Basic: encodedstring', product).and_return stubbed_response
      expect(subject.show_product(product)).to be_kind_of Remote::Product
    end
  end

  describe '#system_migrations' do
    let(:stubbed_response) do
      OpenStruct.new(
        code: 200,
        body: [[{ 'identifier' => 'bravo', 'version' => '12.1' }]],
        success: true
      )
    end

    let(:empty_response) do
      OpenStruct.new(
        code: 200,
        body: [],
        success: true
      )
    end

    let(:products) do
      [
        Remote::Product.new(identifier: 'tango', version: '12'),
        Remote::Product.new(identifier: 'bravo', version: '7')
      ]
    end

    subject { client_instance.system_migrations(products, kind: kind) }

    before do
      allow(client_instance).to receive_messages(system_auth: 'Basic: encodedstring')
    end

    %i[online offline].each do |migration_kind|
      context "with kind #{migration_kind}" do
        let(:kind) { migration_kind }

        it 'calls the API' do
          expect(client_instance.api).to receive(:system_migrations).with('Basic: encodedstring', products, kind: kind).and_return(empty_response)
          subject
        end

        context 'when upgrades are available' do
          before { allow(client_instance.api).to receive(:system_migrations).with('Basic: encodedstring', products, kind: kind).and_return(stubbed_response) }

          it { is_expected.to eq([[ Remote::Product.new(identifier: 'bravo', version: '12.1') ]]) }
        end

        context 'when no upgrades are available' do
          before { allow(client_instance.api).to receive(:system_migrations).with('Basic: encodedstring', products, kind: kind).and_return(empty_response) }

          it { is_expected.to eq([]) }
        end

        context 'with specified target_base_product' do
          subject { client_instance.system_migrations(products, kind: kind, target_base_product: target_base_product) }

          let(:target_base_product) { Remote::Product.new(identifier: 'charlie', version: '15') }

          it 'passes the target_base_product to the API' do
            expect(client_instance.api).to receive(:system_migrations)
              .with('Basic: encodedstring', products, kind: kind, target_base_product: target_base_product)
              .and_return(empty_response)

            subject
          end
        end
      end
    end

    context 'with no specified kind' do
      subject { client_instance.system_migrations(products) }

      specify { expect { subject }.to raise_error(ArgumentError) }
    end
  end

  describe '#deregister!' do
    let(:stubbed_response) { OpenStruct.new(code: 204, body: nil, success: true) }
    subject { client_instance.deregister! }

    before { SUSE::Connect::GlobalLogger.instance.log = string_logger }
    after { SUSE::Connect::GlobalLogger.instance.log = default_logger }

    context 'when system is registered' do
      before do
        allow(client_instance).to receive_messages(system_auth: 'Basic: encodedstring')
        allow(client_instance).to receive(:registered?).and_return true
        allow(client_instance.api).to receive(:deregister).with('Basic: encodedstring').and_return stubbed_response
        allow(System).to receive(:cleanup!).and_return(true)
      end

      it 'calls underlying api and removes credentials file' do
        expect(client_instance.api).to receive(:deregister).with('Basic: encodedstring').and_return stubbed_response
        subject
      end

      it 'cleans up system' do
        expect(System).to receive(:cleanup!).and_return(true)
        subject
      end

      context 'when system is cleaned up' do
        before { allow(System).to receive(:cleanup!).and_return(true) }

        it 'prints confirmation message' do
          expect(string_logger).to receive(:info).with('Successfully deregistered system.')
          subject
        end
      end

      context 'for single product' do
        let(:extension) { SUSE::Connect::Remote::Product.new identifier: 'SLES HA', version: '12', arch: 'x86_64' }
        before do
          config.product = extension
          allow(Zypper).to receive(:base_product).and_return(product)
          stub_request(:delete, 'https://scc.suse.com/connect/systems/products').to_return(body: '{"product":{}}')
        end

        it 'removes SCC service and release package' do
          expect(client_instance).to receive(:deactivate_product) do
            SUSE::Connect::Remote::Service.new({ 'name' => 'dummy', 'product' => {} })
          end
          expect(System).to receive :remove_service
          expect(Zypper).to receive :remove_release_package
          subject
        end

        it 'refreshes SMT service and removes release package' do
          expect(client_instance).to receive(:deactivate_product) do
            SUSE::Connect::Remote::Service.new({ 'name' => 'SMT_DUMMY_NOREMOVE_SERVICE', 'product' => {} })
          end
          expect(Zypper).to receive :refresh_all_services
          expect(Zypper).to receive :remove_release_package
          subject
        end

        it 'logs success' do
          allow(System).to receive :remove_service
          allow(Zypper).to receive :remove_release_package
          expect(string_logger).to receive(:info).with('Deregistered SLES HA 12 x86_64')
          expect(string_logger).to receive(:info).with('To server: https://scc.suse.com')
          subject
        end
      end
    end

    context 'when system is not registered' do
      before { allow(::SUSE::Connect::System).to receive(:credentials).and_return(nil) }

      it { expect { subject }.to raise_error(::SUSE::Connect::SystemNotRegisteredError) }
    end
  end

  describe '#registered?' do
    let(:status) { subject.send(:registered?) }

    context 'system credentials file exists' do
      before { allow(System).to receive(:credentials).and_return true }

      it { expect(status).to be true }
    end

    context 'system credentials file does not exist' do
      before { allow(System).to receive(:credentials).and_return false }

      it { expect(status).to be false }
    end
  end

  describe '#systems_services' do
    let(:stubbed_response) do
      OpenStruct.new(
        code: 204,
        body: nil,
        success: true
      )
    end

    before do
      allow(subject).to receive_messages(system_auth: 'Basic: encodedstring')
    end

    it 'calls underlying api and removes credentials file' do
      allow(subject.api).to receive(:system_services).with('Basic: encodedstring').and_return stubbed_response
      expect(subject.system_services).to eq stubbed_response
    end
  end

  describe '#systems_subscriptions' do
    let(:stubbed_response) do
      OpenStruct.new(
        code: 204,
        body: nil,
        success: true
      )
    end

    before do
      allow(subject).to receive_messages(system_auth: 'Basic: encodedstring')
    end

    it 'calls underlying api and removes credentials file' do
      expect(subject.api).to receive(:system_subscriptions).with('Basic: encodedstring').and_return stubbed_response
      expect(subject.system_subscriptions).to eq stubbed_response
    end
  end

  describe '#systems_activations' do
    let(:stubbed_response) do
      OpenStruct.new(
        code: 200,
        body: nil,
        success: true
      )
    end

    before do
      allow(subject).to receive_messages(system_auth: 'Basic: encodedstring')
    end

    it 'calls underlying api with system_activations call' do
      expect(subject.api).to receive(:system_activations).with('Basic: encodedstring').and_return stubbed_response
      subject.system_activations
    end
  end

  describe '#list_installer_updates' do
    let(:response_body) do
      [
        {
          'id' => 2101,
          'name' => 'SLES12-SP2-Installer-Updates',
          'distro_target' => 'sle-12-x86_64',
          'description' => 'SLES12-SP2-Installer-Updates for sle-12-x86_64',
          'url' => 'https://updates.suse.com/SUSE/Updates/SLE-SERVER-INSTALLER/12-SP2/x86_64/update/',
          'enabled' => false,
          'autorefresh' => true,
          'installer_updates' => true
        }
      ]
    end

    let(:stubbed_response) do
      OpenStruct.new(
        code: 200,
        body: response_body,
        success: true
      )
    end

    let(:product) { Remote::Product.new(identifier: 'SLES', version: '12.2', arch: 'x86_64') }

    it 'collects data from api response' do
      expect(subject.api).to receive(:list_installer_updates).with(product).and_return stubbed_response
      expect(subject.list_installer_updates(product)).to eq response_body
    end
  end
end
