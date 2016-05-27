require 'spec_helper'

describe SUSE::Connect::Client do
  let(:config) { SUSE::Connect::Config.new }
  let(:instance) { described_class.new config }

  subject { instance }

  describe '.new' do
    its(:config) { is_expected.to eq config }
    its(:api) { is_expected.to be_kind_of(Api) }
    it 'hits log' do
      expect(SUSE::Connect::GlobalLogger.instance.log).to receive(:debug)
      subject
    end
  end

  describe '#announce_system' do
    context 'direct_connection' do
      before { config.token = 'blabla' }

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
      context 'direct_connection' do
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

    context 'registration_proxy_connection' do
      before do
        config.url = 'http://smt.local'

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
    let(:product_ident) { { identifier: 'SLES', version: '12', arch: 'x86_64' } }

    before do
      api_response = double('api_response')
      allow(api_response).to receive_messages(body: { 'name' => 'kinkat', 'url' => 'kinkaturl', 'product' => {} })
      allow_any_instance_of(Api).to receive_messages(activate_product: api_response)
      allow(subject).to receive_messages(system_auth: 'secretsecret')
    end

    it 'gets login and password from system' do
      expect(subject).to receive(:system_auth)
      subject.activate_product(product_ident)
    end

    it 'calls underlying api with proper parameters' do
      expect_any_instance_of(Api).to receive(:activate_product).with('secretsecret', product_ident, nil)
      subject.activate_product(product_ident)
    end

    it 'allows to pass an optional parameter "email"' do
      email = 'email@domain.com'
      expect_any_instance_of(Api).to receive(:activate_product).with('secretsecret', product_ident, email)
      subject.activate_product(product_ident, email)
    end

    it 'returns service object' do
      service = subject.activate_product(product_ident)
      expect(service.name).to eq 'kinkat'
      expect(service.url).to eq 'kinkaturl'
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
      expect(subject).to receive(:system_auth).and_return system_auth
    end

    it 'calls underlying api with proper parameters' do
      expect_any_instance_of(Api).to receive(:synchronize).with(system_auth, products)
      subject.synchronize(products)
    end
  end

  describe '#register!' do
    let(:default_logger) { SUSE::Connect::GlobalLogger.instance.log }
    let(:string_logger) { ::Logger.new(StringIO.new) }

    before do
      allow(Zypper).to receive(:base_product).and_return Zypper::Product.new(name: 'SLE_BASE')
      allow(System).to receive(:add_service).and_return true
      allow(Zypper).to receive(:write_base_credentials)
      allow_any_instance_of(Credentials).to receive(:write)
      allow(subject).to receive(:activate_product)
      allow(subject).to receive(:update_system)
      allow(Zypper).to receive(:install_release_package)
    end

    context 'when system is registered' do
      before { allow(System).to receive_messages(credentials?: true) }

      it 'does not call announce' do
        expect(subject).not_to receive(:announce_system)
        subject.register!
      end

      it 'calls update on api' do
        expect(subject).to receive(:update_system)
        subject.register!
      end

      it 'calls activate_product on api' do
        expect(subject).to receive(:activate_product)
        subject.register!
      end

      it 'adds service' do
        expect(System).to receive(:add_service)
        subject.register!
      end

      it 'installs release package on product activation' do
        subject.config.product = Remote::Product.new(identifier: 'SLES')
        expect(Zypper).to receive(:install_release_package).with(subject.config.product.identifier)
        subject.register!
      end

      it 'runs post-register scripts' do
        expect(subject).to receive(:run_post_register_scripts)
        subject.register!
      end
    end

    context 'when system is not registered' do
      before { allow(System).to receive_messages(credentials?: false) }

      it 'should call announce if system not registered' do
        expect(subject).to receive(:announce_system)
        subject.register!
      end

      context 'after announce_system' do
        before { allow(subject).to receive_messages(announce_system: %w{ lg pw }) }

        it 'writes credentials file' do
          expect(Credentials).to receive(:new).with('lg', 'pw', Credentials::GLOBAL_CREDENTIALS_FILE).and_call_original
          subject.register!
        end

        it 'runs post-register scripts' do
          expect(subject).to receive(:run_post_register_scripts)
          subject.register!
        end
      end
    end

    it 'prints message on successful register' do
      product = Zypper::Product.new(name: 'SLES', version: 12, arch: 's390')
      merged_config = config.merge!(url: 'http://dummy:42', email: 'asd@asd.de', product: product, filesystem_root: '/test', language: 'EN')
      client = Client.new(merged_config)
      allow(client).to receive(:announce_or_update)
      allow(client).to receive(:activate_product)
      allow(Zypper).to receive_messages(base_product: product)
      SUSE::Connect::GlobalLogger.instance.log = string_logger

      expect(string_logger).to receive(:info).with('Registered SLES 12 s390')
      expect(string_logger).to receive(:info).with('To server: http://dummy:42')
      expect(string_logger).to receive(:info).with('Using E-Mail: asd@asd.de')
      expect(string_logger).to receive(:info).with('Rooted at: /test')
      client.register!
      SUSE::Connect::GlobalLogger.instance.log = default_logger
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

    let(:product) { Remote::Product.new(identifier: 'text_identifier')  }

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

    before do
      allow(subject).to receive_messages(:system_auth => 'Basic: encodedstring')
    end

    it 'collects data from the API response' do
      expect(subject.api).to receive(:system_migrations).with('Basic: encodedstring', products).and_return(stubbed_response)

      subject.system_migrations(products)
    end

    it 'returns a list of upgrade paths (array of Products) returned from the API' do
      expect(subject.api).to receive(:system_migrations).with('Basic: encodedstring', products).and_return stubbed_response
      upgrade_paths = subject.system_migrations(products)

      expect(upgrade_paths).to be_kind_of Array
      expect(upgrade_paths.first).to be_kind_of Array
      expect(upgrade_paths.first.first).to be_kind_of Remote::Product
    end

    context 'when no upgrades are available' do
      it 'returns an empty array' do
        expect(subject.api).to receive(:system_migrations).with('Basic: encodedstring', products).and_return empty_response
        upgrade_paths = subject.system_migrations(products)
        expect(upgrade_paths).to match_array([])
      end
    end
  end

  describe '#deregister!' do
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
      expect(subject.api).to receive(:deregister).with('Basic: encodedstring').and_return stubbed_response
      expect(System).to receive(:cleanup!).and_return(true)

      subject.deregister!
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

  describe '#run_post_register_scripts' do
    let(:product) { Zypper::Product.new name: 'SLES', version: 12, arch: 's390' }
    subject { instance.run_post_register_scripts product }

    context 'when path is absent' do
      before { instance.config.post_register_scripts_path = '/non-existing-dir' }

      it 'executes nothing' do
        expect(Kernel).not_to receive(:system)
        subject
      end

      it 'hits log' do
        expect(SUSE::Connect::GlobalLogger.instance.log).to receive(:debug)
        subject
      end
    end

    context 'when path exists' do
      before { instance.config.post_register_scripts_path = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/post_install_scripts/successful')) }

      it 'executes everything' do
        expect(Kernel).to receive(:system).with(/script_1.callback SLES/)
        expect(Kernel).to receive(:system).with(/script_2.callback SLES/)
        subject
      end

      context 'and contains failing scripts' do
        before { instance.config.post_register_scripts_path = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/post_install_scripts/failing')) }

        it { expect { subject }.not_to raise_error }

        it 'executes everything' do
          expect(Kernel).to receive(:system).twice
          subject
        end
      end
    end
  end
end
