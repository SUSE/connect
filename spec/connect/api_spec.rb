require 'spec_helper'

describe SUSE::Connect::Api do
  subject { SUSE::Connect::Api }

  let(:config) do
    double('config',
           url: 'https://example.com',
           language: 'Klingon',
           insecure: false,
           verify_callback: nil,
           debug: false,
           token: 'token-shmocken')
  end

  describe '.new' do
    it 'requires a config object and raises if nothing was supplied' do
      expect { subject.new }.to raise_error ArgumentError
    end

    it 'requires a config object to initialize the class instance' do
      expect { subject.new(config) }.not_to raise_error
    end
  end

  before do
    # If the credentials file exists on the system it might try to read it
    # after a request in order to update the `system_token` attribute. Skip
    # this on the following tests.
    allow(::SUSE::Connect::System).to receive(:credentials?).and_return(false)
  end

  describe '#announce_system' do
    let(:payload) do
      [
        '/connect/subscriptions/systems',
        auth: 'token',
        params: {
          hostname: 'connect',
          hwinfo: 'hwinfo',
          distro_target: 'HHH'
        }
      ]
    end

    before do
      stub_announce_call
      allow(Socket).to receive_messages(gethostname: 'connect')
      allow(System).to receive_messages(hwinfo: 'hwinfo')
      allow(Zypper).to receive_messages(write_base_credentials: true)
      allow(Zypper).to receive_messages(distro_target: 'HHH')
    end

    mock_dry_file

    it 'sends a call with proper payload to api' do
      expect_any_instance_of(Connection).to receive(:post).with(*payload).and_call_original
      subject.new(config).announce_system('token')
    end

    it 'sends a call with passed on distro_target parameter' do
      args = payload.clone
      args.last[:params][:distro_target] = 'aaaaaaaa'

      expect_any_instance_of(Connection).to receive(:post).with(*args).and_call_original
      subject.new(config).announce_system('token', 'aaaaaaaa')
    end

    it 'won\'t access Zypper if the optional parameter "distro_target" is set' do
      expect(Zypper).to receive(:distro_target).never
      expect_any_instance_of(Connection).to receive(:post).and_call_original
      subject.new(config).announce_system('token', 'optional_target')
    end

    it 'sets instance data in payload' do
      expect_any_instance_of(Connection).to receive(:post)
        .with('/connect/subscriptions/systems',
              auth: 'token',
              params: { hostname: 'connect', hwinfo: 'hwinfo', distro_target: 'HHH', instance_data: '<test>' })
        .and_call_original
      subject.new(config).announce_system('token', nil, '<test>')
    end

    it 'sets namespace data in payload' do
      namespace = 'SMT namespace'

      expect_any_instance_of(Connection).to receive(:post)
        .with('/connect/subscriptions/systems',
              auth: 'token',
              params: { hostname: 'connect', hwinfo: 'hwinfo', distro_target: 'HHH', namespace: namespace })
        .and_call_original
      subject.new(config).announce_system('token', nil, nil, namespace)
    end

    context :hostname_detected do
      it 'sends a call with hostname' do
        payload = ['/connect/subscriptions/systems', auth: 'token', params: {
          hostname: 'connect', hwinfo: 'hwinfo', distro_target: 'HHH'
        }]
        expect_any_instance_of(Connection).to receive(:post).with(*payload).and_call_original
        subject.new(config).announce_system('token')
      end
    end

    context :no_hostname do
      it 'sends a call with ip when hostname is nil' do
        allow(Socket).to receive_messages(gethostname: nil)
        allow(Socket).to receive_messages(ip_address_list: [Addrinfo.ip('192.168.42.42')])
        payload = ['/connect/subscriptions/systems', auth: 'token', params: {
          hostname: '192.168.42.42', hwinfo: 'hwinfo', distro_target: 'HHH'
        }]
        expect_any_instance_of(Connection).to receive(:post).with(*payload).and_call_original
        subject.new(config).announce_system('token')
      end
    end
  end

  describe :systems do
    before do
      stub_systems_services_call
    end

    mock_dry_file

    describe :services do
      it 'returns returns array of services as known by the system' do
        expect_any_instance_of(Connection).to receive(:get).with('/connect/systems/services', auth: 'basic_auth_string').and_call_original
        subject.new(config).system_services('basic_auth_string')
      end

      it 'holds expected structure' do
        expect_any_instance_of(Connection).to receive(:get).with('/connect/systems/services', auth: 'basic_auth_string').and_call_original
        result = subject.new(config).system_services('basic_auth_string').body
        expect(result).to be_kind_of Array
        expect(result.first.keys).to match_array %w[id name product]
      end
    end

    describe :subscriptions do
      before do
        stub_systems_subscriptions_call
      end

      it 'returns returns array of subscriptions known by the system' do
        expect_any_instance_of(Connection).to receive(:get).with('/connect/systems/subscriptions', auth: 'basic_auth_string').and_call_original
        subject.new(config).system_subscriptions('basic_auth_string')
      end

      it 'holds expected structure' do
        expect_any_instance_of(Connection).to receive(:get).with('/connect/systems/subscriptions', auth: 'basic_auth_string').and_call_original
        result = subject.new(config).system_subscriptions('basic_auth_string').body
        expect(result).to be_kind_of Array

        attr_ary = %w[id regcode name type status starts_at expires_at]
        attr_ary += %w[system_limit systems_count virtual_count product_classes systems product_ids]
        expect(result.first.keys).to eq attr_ary
      end
    end

    describe :activations do
      before do
        stub_systems_activations_call
      end

      it 'returns returns array of subscriptions known by the system' do
        expect_any_instance_of(Connection).to receive(:get).with('/connect/systems/activations', auth: 'basic_auth_string').and_call_original
        subject.new(config).system_activations('basic_auth_string')
      end

      it 'holds expected structure' do
        expect_any_instance_of(Connection).to receive(:get).with('/connect/systems/activations', auth: 'basic_auth_string').and_call_original
        result = subject.new(config).system_activations('basic_auth_string').body
        expect(result).to be_kind_of Array
        expect(result.first.keys).to eq %w[id regcode type status starts_at expires_at system_id service]
      end
    end
  end

  describe '#activate_product' do
    let(:api_endpoint) { '/connect/systems/products' }
    let(:system_auth) { 'basic_auth_mock' }

    let(:product) { Remote::Product.new(identifier: 'SLES', version: '11-SP2', arch: 'x86_64', token: 'token-shmocken') }

    let(:payload) do
      {
        identifier:   'SLES',
        version:      '11-SP2',
        arch:         'x86_64',
        release_type: nil,
        token:        'token-shmocken',
        email:        nil
      }
    end

    it 'calls ConnectAPI with basic auth and params and receives a JSON in return (use proper webmock)' do
      stub_activate_call
      expect_any_instance_of(Connection).to receive(:post)
        .with(api_endpoint, auth: system_auth, params: payload)
        .and_call_original
      response = subject.new(config).activate_product(system_auth, product)
      expect(response.body['name']).to eq 'SUSE_Linux_Enterprise_Server_12_x86_64'
    end

    it 'allows to add an optional parameter "email"' do
      email = 'email@domain.com'
      payload[:email] = email
      expect_any_instance_of(Connection).to receive(:post)
        .with(api_endpoint, auth: system_auth, params: payload)
      subject.new(config).activate_product(system_auth, product, email)
    end
  end

  describe '#upgrade_product' do
    let(:api_endpoint) { '/connect/systems/products' }
    let(:system_auth) { 'basic_auth_mock' }
    let(:product) { Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64', release_type: 'aaaa') }
    let(:openstruct_product) { product.to_openstruct }

    it 'calls ConnectAPI with basic auth and params and receives a JSON in return' do
      expect_any_instance_of(Connection).to receive(:put).with(api_endpoint, auth: system_auth, params: openstruct_product.to_params)
      subject.new(config).upgrade_product(system_auth, openstruct_product)
    end
  end

  describe '#downgrade_product' do
    let(:system_auth) { 'basic_auth_mock' }
    let(:product) { Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64', release_type: 'aaaa') }

    it 'is an alias method for upgrade_product' do
      expect(subject.new(config)).to respond_to(:downgrade_product)
    end

    it 'is accepts parameters' do
      allow_any_instance_of(Connection).to receive(:put).and_return true
      subject.new(config).downgrade_product(system_auth, product)
    end
  end

  describe '#synchronize' do
    let(:api_endpoint) { '/connect/systems/products/synchronize' }
    let(:system_auth) { 'basic_auth_mock' }
    let(:products) { [SUSE::Connect::Zypper::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64', release_type: nil)] }

    it 'syncs activated system products with SCC' do
      expect_any_instance_of(Connection).to receive(:post).with(api_endpoint, auth: system_auth, params: { products: products.map(&:to_params) })
      subject.new(config).synchronize(system_auth, products)
    end
  end

  describe 'system products' do
    before do
      stub_show_product_call
    end

    let(:product) { Remote::Product.new(identifier: 'rodent', version: 'good', arch: 'z42', release_type: 'foo') }

    it 'is authenticated via basic auth' do
      payload = [
        '/connect/systems/products',
        auth: 'Basic: encodedgibberish',
        params: product.to_params
      ]
      expect_any_instance_of(Connection).to receive(:get)
        .with(*payload)
        .and_call_original
      subject.new(config).show_product('Basic: encodedgibberish', product)
    end

    it 'responds with proper status code' do
      response = subject.new(config).show_product('Basic: encodedgibberish', product)
      expect(response.code).to eq 200
    end

    it 'returns array of extensions' do
      body = subject.new(config).show_product('Basic: encodedgibberish', product).body
      expect(body).to be_kind_of Hash
    end
  end

  describe "#system_migrations" do
    shared_examples 'a query with no specified target base that returns migration paths in the correct order' do |kind|
      before { stub_system_migrations_call(kind, products) }

      let(:query) { { installed_products: products.map(&:to_params) } }
      let(:products) do
        [
          Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64', release_type: 'HP-CNB', isbase: true)
        ]
      end

      context 'with SLES as base product' do
        its(:code) { is_expected.to eq 200 }
        its(:body) do
          is_expected.to match_array(
            [
              [{ 'identifier' => 'SLES', 'version' => '12.2', 'arch' => 'x86_64', 'release_type' => 'HP-CNB' }],
              [{ 'identifier' => 'SLES', 'version' => '12.1', 'arch' => 'x86_64', 'release_type' => 'HP-CNB' }],
              [{ 'identifier' => 'SLE-HPC', 'version' => '12.2', 'arch' => 'x86_64', 'release_type' => nil }],
              [{ 'identifier' => 'SLE-HPC', 'version' => '12.1', 'arch' => 'x86_64', 'release_type' => nil }]
            ]
          )
        end
      end

      context 'with SLE-HPC as base product' do
        let(:products) do
          [
            Remote::Product.new(identifier: 'SLE-HPC', version: '12', arch: 'x86_64', release_type: 'test', isbase: true)
          ]
        end

        its(:code) { is_expected.to eq 200 }
        its(:body) do
          is_expected.to match_array(
            [
              [{ 'identifier' => 'SLE-HPC', 'version' => '12.2', 'arch' => 'x86_64', 'release_type' => nil }],
              [{ 'identifier' => 'SLE-HPC', 'version' => '12.1', 'arch' => 'x86_64', 'release_type' => nil }],
              [{ 'identifier' => 'SLES', 'version' => '12.2', 'arch' => 'x86_64', 'release_type' => 'HP-CNB' }],
              [{ 'identifier' => 'SLES', 'version' => '12.1', 'arch' => 'x86_64', 'release_type' => 'HP-CNB' }]
            ]
          )
        end
      end


      it 'is authenticated via basic auth' do
        payload = [
          "/connect/systems/products/#{(kind == :offline) ? 'offline_' : ''}migrations",
          auth: 'Basic: encodedgibberish',
          params: query
        ]
        expect_any_instance_of(Connection).to receive(:post)
          .with(*payload)
          .and_call_original

        subject
      end
    end

    shared_examples 'a query with a specific target base that returns migration paths' do |kind|
      before { stub_system_migrations_call_with_target_product(kind) }

      let(:products) { [ Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64') ] }
      let(:target_base_product) { Remote::Product.new(identifier: 'SLES', version: '15.0', arch: 'x86_64') }

      let(:query) do
        {
          installed_products: products.map(&:to_params),
          target_base_product: target_base_product.to_params
        }
      end

      its(:code) { is_expected.to eq 200 }
      its(:body) do
        is_expected.to match_array([[
          { 'identifier' => 'SLES', 'version' => '15.0', 'arch' => 'x86_64', 'release_type' => nil }
        ]])
      end

      it 'is authenticated via basic auth' do
        payload = [
          "/connect/systems/products/#{(kind == :offline) ? 'offline_' : ''}migrations",
          auth: 'Basic: encodedgibberish',
          params: query
        ]
        expect_any_instance_of(Connection).to receive(:post)
          .with(*payload)
          .and_call_original

        subject
      end
    end

    shared_examples 'a query with no specified target base that returns no migration paths' do |kind|
      before { stub_empty_system_migrations_call(kind) }

      let(:products) { [ Remote::Product.new(identifier: 'SLES', version: 'not-upgradeable', arch: 'x86_64', release_type: nil) ] }

      its(:body) { is_expected.to be_empty }
    end

    let(:api) { SUSE::Connect::Api }

    %i[online offline].each do |kind|
      context "with kind #{kind}" do
        subject { api.new(config).system_migrations('Basic: encodedgibberish', products, kind: kind) }

        it_behaves_like 'a query with no specified target base that returns migration paths in the correct order', kind
        it_behaves_like 'a query with no specified target base that returns no migration paths', kind
      end

      context 'with a target base product' do
        subject { api.new(config).system_migrations('Basic: encodedgibberish', products, kind: kind, target_base_product: target_base_product) }

        it_behaves_like 'a query with a specific target base that returns migration paths', kind
      end
    end

    context 'with no specified kind' do
      subject { api.new(config).system_migrations('Basic: encodedgibberish', []) }

      specify { expect { subject }.to raise_error(ArgumentError, 'missing keyword: kind') }
    end

    context 'with a kind that is not :online nor :offline' do
      subject { api.new(config).system_migrations('Basic: encodedgibberish', [], kind: :bad) }

      specify { expect { subject }.to raise_error(KeyError, 'key not found: :bad') }
    end
  end

  describe '#deregister' do
    before do
      stub_deregister_call
    end

    it 'is authenticated via basic auth' do
      payload = [
        '/connect/systems',
        auth: 'Basic: encodedgibberish'
      ]

      expect_any_instance_of(Connection).to receive(:delete)
        .with(*payload)
        .and_call_original

      subject.new(config).deregister('Basic: encodedgibberish')
    end

    it 'responds with proper status code' do
      response = subject.new(config).deregister('Basic: encodedgibberish')
      expect(response.code).to eq 204
    end

    it 'returns empty body' do
      body = subject.new(config).deregister('Basic: encodedgibberish').body
      expect(body).to be_nil
    end
  end

  describe '#update_system' do
    before do
      stub_update_call
      allow(System).to receive_messages(hostname: 'connect')
      allow(System).to receive_messages(hwinfo: 'hwinfo')
      allow(Zypper).to receive_messages(distro_target: 'openSUSE-4.1-x86_64')
    end

    it 'is authenticated via basic auth' do
      payload = [
        '/connect/systems',
        auth: 'Basic: encodedgibberish', params: { hostname: 'connect', hwinfo: 'hwinfo',
                                                   distro_target: 'openSUSE-4.1-x86_64' }
      ]
      expect_any_instance_of(Connection).to receive(:put).with(*payload).and_call_original
      subject.new(config).update_system('Basic: encodedgibberish')
    end

    it 'responds with proper status code' do
      response = subject.new(config).update_system('Basic: encodedgibberish')
      expect(response.code).to eq 204
    end

    it 'returns empty body' do
      body = subject.new(config).update_system('Basic: encodedgibberish').body
      expect(body).to be_nil
    end

    it 'sets namespace data in payload' do
      namespace = 'SMT namespace'

      params = { hostname: 'connect', hwinfo: 'hwinfo', distro_target: 'openSUSE-4.1-x86_64', namespace: namespace }
      payload = [
        '/connect/systems',
        auth: 'Basic: encodedgibberish',
        params: params
      ]

      expect_any_instance_of(Connection).to receive(:put).with(*payload).and_call_original
      subject.new(config).update_system('Basic: encodedgibberish', nil, nil, namespace)
    end
  end

  describe '#list_installer_updates' do
    before { stub_list_installer_updates_call }

    let(:product) { Remote::Product.new(identifier: 'SLES', version: '12.2', arch: 'x86_64') }
    let(:expected_body) do
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

    it 'returns a list of repositories' do
      body = subject.new(config).list_installer_updates(product).body
      expect(body).to eq expected_body
    end
  end

  describe '#up_to_date?' do
    subject { SUSE::Connect::Api.new(config).up_to_date? }
    let!(:stubbed_request) { stub_request(:get, 'https://example.com/connect/repositories/installer') }

    it 'sends request to the `/connect/repositories/installer` endpoint' do
      subject
      expect(stubbed_request).to have_been_made
    end

    context 'if there is a 422 error' do
      before { stubbed_request.to_return(status: 422, body: '{}') }
      it { is_expected.to be_truthy }
    end

    context 'if there is 404 error' do
      before { stubbed_request.to_return(status: 404, body: '{}') }
      it { is_expected.to be_falsey }
    end

    context 'if something weird happens and server responds with 200 and JSON' do
      before { stubbed_request.to_return(status: 200, body: '{"success": true}') }
      it { is_expected.to be_falsey }
    end

    context 'if server responds with XML instead of JSON' do
      before { stubbed_request.to_return(status: 404, body: File.read('spec/fixtures/old_smt_404_error.html')) }
      it { expect { subject }.not_to raise_error }
    end
  end

  describe '#deactivate_product' do
    let(:product) { SUSE::Connect::Remote::Product.new identifier: 'sles', version: '12', arch: 'x86_64' }
    let!(:stubbed_request) do
      stub_request(:delete, 'https://example.com/connect/systems/products')
        .with(headers: { 'Authorization' => 'foo_token' }, body: "{\"identifier\":\"sles\",\"version\":\"12\",\"arch\":\"x86_64\",\"release_type\":null}")
    end

    subject { SUSE::Connect::Api.new(config).deactivate_product 'foo_token', product }

    it 'performs request' do
      subject
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#package_search' do
    let(:product) { SUSE::Connect::Zypper::Product.new name: 'SLES', version: '15', arch: 'x86_64' }

    context 'supported' do
      let(:query) { 'https://example.com/api/package_search/packages?product_id=SLES/15/x86_64&query=vim' }

      let!(:stubbed_request) do
        stub_request(:get, query).with(headers: {
          'Accept' => 'application/json,application/vnd.scc.suse.com.v4+json',
          'Content-Type' => 'application/json'
        }).to_return(status: 200, body: "[{}]", headers: {})
      end

      it 'performs the request and set the query params correctly' do
        expect(CGI).to receive(:escape).twice.and_call_original
        expect(product).to receive(:to_triplet).and_call_original

        subject.new(config).package_search(product, "vim")
        expect(stubbed_request).to have_been_made
      end
    end

    context 'unsupported' do
      let(:query) { 'https://example.com/api/package_search/packages?product_id=SLES/15/x86_64&query=docker' }

      let!(:stubbed_request) do
        stub_request(:get, query).with(headers: {
          'Accept' => 'application/json,application/vnd.scc.suse.com.v4+json',
          'Content-Type' => 'application/json'
        }).to_return(status: 404, body: "{}", headers: {})
      end

      it 'performs the request and raises an error' do
        expect(CGI).to receive(:escape).twice.and_call_original
        expect(product).to receive(:to_triplet).and_call_original

        expect { subject.new(config).package_search(product, "docker") }.to raise_error(SUSE::Connect::UnsupportedOperation)
        expect(stubbed_request).to have_been_made
      end
    end

    context 'not working host' do
      let(:query) { 'https://example.com/api/package_search/packages?product_id=SLES/15/x86_64&query=libguestfs' }

      let!(:stubbed_request) do
        stub_request(:get, query).with(headers: {
          'Accept' => 'application/json,application/vnd.scc.suse.com.v4+json',
          'Content-Type' => 'application/json'
        }).to_return(status: 500, body: "{}", headers: {})
      end

      it 'performs the request and raises an error' do
        expect(CGI).to receive(:escape).twice.and_call_original
        expect(product).to receive(:to_triplet).and_call_original

        expect { subject.new(config).package_search(product, "libguestfs") }.to raise_error(SUSE::Connect::ApiError)
        expect(stubbed_request).to have_been_made
      end
    end
  end
end
