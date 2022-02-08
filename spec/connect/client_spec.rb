require 'spec_helper'

describe SUSE::Connect::Client do
  before do
    stub_const('SUSE::Connect::Config::DEFAULT_CONFIG_FILE', 'spec/fixtures/SUSEConnect')
  end
  let(:config) { SUSE::Connect::Config.new }
  let(:default_logger) { SUSE::Connect::GlobalLogger.instance.log }
  let(:string_logger) { ::Logger.new(StringIO.new) }
  let(:client_instance) { described_class.new config }

  let(:product_tree) { JSON.parse(File.read('spec/fixtures/product_tree.json')) }
  let(:product) { Remote::Product.new(product_tree) }

  let(:recommended_2) { product.extensions[1] }
  let(:recommended_2_2) { recommended_2.extensions[1] }
  let(:recommended_3) { product.extensions[2] }

  let(:extension_4) { product.extensions[3] }
  let(:extension_4_2) { extension_4.extensions[1] }

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
        SUSE::Connect::GlobalLogger.instance.log = string_logger
        api_response = double('api_response')
        allow(api_response).to receive_messages(body: { 'login' => 'lg', 'password' => 'pw' })
        allow_any_instance_of(Api).to receive_messages(announce_system: api_response)
        allow(subject).to receive_messages(token_auth: 'auth')
      end

      after { SUSE::Connect::GlobalLogger.instance.log = default_logger }

      it 'reports about ongoing action' do
        expect(string_logger).to receive(:info).with("\e[1m\nAnnouncing system to #{config.url} ...\e[22m")
        subject.announce_system
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
          SUSE::Connect::GlobalLogger.instance.log = string_logger
          allow(subject).to receive_messages(system_auth: 'auth')
          allow_any_instance_of(Api).to receive(:update_system)
        end

        after { SUSE::Connect::GlobalLogger.instance.log = default_logger }

        it 'reports about ongoing action' do
          expect(string_logger).to receive(:info).with("\e[1m\nUpdating system details on #{config.url} ...\e[22m")
          subject.update_system
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
      allow(subject).to receive(:announce_system)
      SUSE::Connect::GlobalLogger.instance.log = string_logger
    end

    after do
      SUSE::Connect::GlobalLogger.instance.log = default_logger
    end

    context 'when the system is not registered' do
      it 'announces the system' do
        expect(subject).to receive(:announce_system)
        subject.register!
      end

      it 'writes credentials file' do
        allow(System).to receive_messages(credentials?: false)
        allow(subject).to receive_messages(announce_system: %w[lg pw])
        expect(Credentials).to receive(:new).with('lg', 'pw', Credentials::GLOBAL_CREDENTIALS_FILE)
          .and_return(double(write: true))
        subject.register!
      end

      it 'calls register_product for the base product' do
        expect(subject).to receive(:register_product).with(product, false)
        subject.register!
      end

      it 'calls register_product for all recommended extensions' do
        [recommended_2, recommended_2_2, recommended_3].each do |ext|
          expect(subject).to receive(:register_product).with(ext)
        end
        subject.register!
      end

      context 'with default config url' do
        it 'prints message on successful activation' do
          expect(subject).to receive(:register_product).exactly(4).times
          expect(string_logger).to receive(:info).with("\e[1mRegistering system to SUSE Customer Center\e[22m")
          expect(string_logger).to receive(:info).with("\e[1m\e[32m\nSuccessfully registered system\n\e[0m\e[22m")
          subject.register!
        end
      end

      context 'with registration proxy url' do
        before { config.url = 'https://rmt.mydomain' }

        it 'prints message on successful activation' do
          expect(subject).to receive(:register_product).exactly(4).times
          expect(string_logger).to receive(:info).with("\e[1mRegistering system to registration proxy #{config.url}\e[22m")
          expect(string_logger).to receive(:info).with("\e[1m\e[32m\nSuccessfully registered system\n\e[0m\e[22m")
          subject.register!
        end
      end
    end

    context 'when a leaf recommended extension is not available' do
      before { recommended_3.available = false }

      it 'does not register the unavailable extension' do
        expect(subject).to receive(:register_product).with(recommended_2)
        expect(subject).to receive(:register_product).with(recommended_2_2)
        expect(subject).not_to receive(:register_product).with(recommended_3)
        subject.register!
      end
    end

    context 'when a branch recommended extension is not available' do
      before { recommended_2.available = false }

      it 'does not register the unavailable extension nor its children' do
        expect(subject).not_to receive(:register_product).with(recommended_2)
        expect(subject).not_to receive(:register_product).with(recommended_2_2)
        expect(subject).to receive(:register_product).with(recommended_3)
        subject.register!
      end
    end

    context 'when the system is registered' do
      it 'updates the system instead of announcing it' do
        allow(System).to receive_messages(credentials?: true)
        expect(subject).not_to receive(:announce_system)
        expect(subject).to receive(:update_system)
        subject.register!
      end
    end
  end

  describe '#register_product' do
    let(:service_stub) { 'service_stub' }
    let(:fake_email) { 'email@email.org.what.ever' }

    before do
      config.email = fake_email
      SUSE::Connect::GlobalLogger.instance.log = string_logger
    end

    after do
      SUSE::Connect::GlobalLogger.instance.log = default_logger
    end

    context 'when no_zypper_refs is false' do
      context 'when install_release_package is true' do
        it 'activates the product, add the service, refreshes the service and installs release package' do
          expect(subject).to receive(:activate_product).with(product, fake_email).and_return service_stub
          expect(System).to receive(:add_service).with(service_stub, true)

          expect(Zypper).to receive(:install_release_package).with(product.identifier)

          subject.register_product(product)
        end
      end

      context 'when install_release_package is false' do
        it "refreshes the service, doesn't install the release package" do
          expect(subject).to receive(:activate_product).with(product, fake_email).and_return service_stub
          expect(System).to receive(:add_service).with(service_stub, true)

          expect(Zypper).not_to receive(:install_release_package)

          subject.register_product(product, false)
        end
      end
    end

    context 'when no_zypper_refs is true' do
      let(:config) do
        SUSE::Connect::Config.new.merge!({ 'no_zypper_refs' => true })
      end

      before do
        allow(SUSE::Connect::Config).to receive(:new).and_return(config)
      end

      context 'when install_release_package is true' do
        it "activates the product, adds service file, doesn't refresh the service and installs release package" do
          expect(subject).to receive(:activate_product).with(product, fake_email).and_return service_stub
          expect(System).to receive(:add_service).with(service_stub, false)

          expect(Zypper).to receive(:install_release_package).with(product.identifier)

          subject.register_product(product)
        end
      end

      context 'when install_release_package is false' do
        it "doesn't refresh the service, doesn't not install the release package" do
          expect(subject).to receive(:activate_product).with(product, fake_email).and_return service_stub
          expect(System).to receive(:add_service).with(service_stub, false)

          expect(Zypper).not_to receive(:install_release_package)

          subject.register_product(product, false)
        end
      end
    end

    it 'informs the user about progress' do
      allow(subject).to receive(:activate_product)
      allow(System).to receive(:add_service)
      allow(Zypper).to receive(:install_release_package)

      expect(string_logger).to receive(:info).with("\nActivating SLES 15 x86_64 ...")
      expect(string_logger).to receive(:info).with('-> Adding service to system ...')
      expect(string_logger).to receive(:info).with('-> Installing release package ...')
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
    let(:product_list) { [product] }
    let(:base_product_service) { SUSE::Connect::Remote::Service.new({ 'name' => 'dummy_base_product', 'product' => {} }) }

    subject { client_instance.deregister! }

    before { SUSE::Connect::GlobalLogger.instance.log = string_logger }
    after { SUSE::Connect::GlobalLogger.instance.log = default_logger }

    context 'when system is registered' do
      before do
        allow(client_instance).to receive_messages(system_auth: 'Basic: encodedstring')
        allow(client_instance).to receive(:registered?).and_return true
        allow(client_instance.api).to receive(:deregister).with('Basic: encodedstring').and_return stubbed_response
        allow(System).to receive(:cleanup!).and_return(true)
        allow(Zypper).to receive(:base_product).and_return(product)
        allow(Zypper).to receive(:installed_products).and_return(product_list)
        allow(client_instance).to receive(:show_product).and_return(product)
        allow(client_instance).to receive(:upgrade_product).and_return base_product_service
        allow(System).to receive(:remove_service).with(base_product_service)
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
          expect(string_logger).to receive(:info).with("\e[1mDeregistering system from SUSE Customer Center\e[22m")
          expect(string_logger).to receive(:info).with('-> Removing service from system ...')
          expect(string_logger).to receive(:info).with("\nCleaning up ...")
          expect(string_logger).to receive(:info).with("\e[1m\e[32mSuccessfully deregistered system\n\e[0m\e[22m")
          subject
        end
      end

      context 'without specified product' do
        let(:installed_products) do
          [
            recommended_2_2,
            extension_4,
            recommended_2,
            extension_4_2,
            product
          ]
        end

        let(:product_service) { SUSE::Connect::Remote::Service.new({ 'name' => 'dummy', 'product' => {} }) }

        before do
          stub_request(:delete, 'https://scc.suse.com/connect/systems/products').to_return(body: '{"product":{}}')
          allow(System).to receive(:cleanup!).and_return(true)
          allow(System).to receive :remove_service
          allow(Zypper).to receive :remove_release_package
          allow(Zypper).to receive(:installed_products).and_return installed_products
          allow(client_instance).to receive(:show_product).and_return product
          allow(client_instance).to receive(:upgrade_product).and_return base_product_service
        end

        it 'removes all extensions if no product was specified' do
          [extension_4_2, extension_4, recommended_2_2, recommended_2].each do |ext|
            expect(client_instance).to receive(:deregister_product).with(ext).ordered
          end
          subject
        end

        it 'removes SCC service and release package for extension' do
          expect(client_instance).not_to receive(:deactivate_product).with(product)
          expect(System).to receive(:remove_service).with(base_product_service)
          [extension_4_2, extension_4, recommended_2_2, recommended_2].each do |ext|
            expect(client_instance).to receive(:deactivate_product).with(ext).and_return product_service
            expect(System).to receive(:remove_service).with(product_service)
            expect(Zypper).to receive(:remove_release_package).with(ext[:identifier])
          end
          subject
        end
        it 'reports about ongoing action' do
          expect(string_logger).to receive(:info).with("\e[1mDeregistering system from SUSE Customer Center\e[22m")
          expect(string_logger).to receive(:info).with("\nDeactivating 4-2-Extension 83 x86_64 ...")
          expect(string_logger).to receive(:info).with("\nDeactivating 4-Extension 1337 x86_64 ...")
          expect(string_logger).to receive(:info).with("\nDeactivating 2-2-Recommended 83 x86_64 ...")
          expect(string_logger).to receive(:info).with("\nDeactivating 2-Recommended 15 x86_64 ...")
          expect(string_logger).to receive(:info).with('-> Removing service from system ...').exactly(5).times
          expect(string_logger).to receive(:info).with('-> Removing release package ...').exactly(4).times
          expect(string_logger).to receive(:info).with("\nCleaning up ...")
          expect(string_logger).to receive(:info).with("\e[1m\e[32mSuccessfully deregistered system\n\e[0m\e[22m")
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
          expect(string_logger).to receive(:info).with("\e[1mDeregistering system from SUSE Customer Center\e[22m")
          expect(string_logger).to receive(:info).with("\nDeactivating SLES HA 12 x86_64 ...")
          expect(string_logger).to receive(:info).with('-> Removing service from system ...')
          expect(string_logger).to receive(:info).with('-> Removing release package ...')
          subject
        end
      end
    end

    context 'when system is not registered' do
      before { allow(::SUSE::Connect::System).to receive(:credentials).and_return(nil) }

      it { expect { subject }.to raise_error(::SUSE::Connect::SystemNotRegisteredError) }
    end


    context 'when running on on-demand instance' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('/usr/sbin/registercloudguest').and_return(true)
        allow(client_instance).to receive(:registered?).and_return true
      end

      context 'with no product' do
        before { allow_any_instance_of(Config).to receive(:product).and_return(false) }

        it { expect { subject }.to raise_error(::SUSE::Connect::UnsupportedOperation) }
      end

      context 'with product' do
        before do
          allow(client_instance).to receive(:deregister_product)
          allow(client_instance.config).to receive(:product).and_return(true)
        end

        it { expect { subject }.not_to raise_error }
      end
    end
  end

  describe '#keepalive!' do
    let(:stubbed_response) { OpenStruct.new(code: 204, body: nil, success: true) }

    subject { client_instance.keepalive! }

    before { SUSE::Connect::GlobalLogger.instance.log = string_logger }
    after { SUSE::Connect::GlobalLogger.instance.log = default_logger }

    context 'when system is registered' do
      before do
        allow(client_instance).to receive_messages(system_auth: 'Basic: encodedstring')
        allow(client_instance).to receive(:registered?).and_return true
        allow(client_instance.api).to receive(:update_system).with('Basic: encodedstring').and_return stubbed_response
      end

      it 'calls underlying api and sends data to SCC' do
        expect(client_instance.api).to receive(:update_system).with('Basic: encodedstring').and_return stubbed_response
        subject
      end
    end

    context 'when system is not registered' do
      before { allow(::SUSE::Connect::System).to receive(:credentials).and_return(nil) }

      it { expect { subject }.to raise_error(::SUSE::Connect::PingNotAllowed) }
    end
  end

  describe '#flatten_tree' do
    let(:identifiers) do
      [
        '1-Extension',
        '2-Recommended',
        '2-1-Extension',
        '2-2-Recommended',
        '3-Recommended',
        '4-Extension',
        '4-1-Extension',
        '4-2-Extension'
      ]
    end

    it 'returns all products in a tree' do
      result = subject.flatten_tree(product).map(&:identifier)
      expect(result).to eq identifiers
    end

    it 'returns an empty array when there are no extensions' do
      result = subject.flatten_tree(recommended_3)
      expect(result).to be_empty
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
