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
           token: 'token-shmocken'
          )
  end

  let(:client) { double('client', config: config) }

  describe '.new' do
    it 'require client object' do
      expect { subject.new }.to raise_error ArgumentError
    end

    it 'require client object' do
      expect { subject.new(client) }.not_to raise_error
    end
  end

  describe 'announce_system' do
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
      Socket.stub(gethostname: 'connect')
      System.stub(hwinfo: 'hwinfo')
      Zypper.stub(write_base_credentials: true)
      Zypper.stub(distro_target: 'HHH')
    end

    mock_dry_file

    it 'sends a call with proper payload to api' do
      Connection.any_instance.should_receive(:post).with(*payload).and_call_original
      subject.new(client).announce_system('token')
    end

    it 'sends a call with passed on distro_target parameter' do
      args = payload.clone
      args.last[:params][:distro_target] = 'aaaaaaaa'

      Connection.any_instance.should_receive(:post).with(*args).and_call_original
      subject.new(client).announce_system('token', 'aaaaaaaa')
    end

    it 'won\'t access Zypper if the optional parameter "distro_target" is set' do
      Zypper.should_receive(:distro_target).never
      Connection.any_instance.should_receive(:post).and_call_original
      subject.new(client).announce_system('token', 'optional_target')
    end

    it 'sets instance data in payload' do
      Connection.any_instance.should_receive(:post)
        .with('/connect/subscriptions/systems',
              auth: 'token',
              params: { hostname: 'connect', hwinfo: 'hwinfo', distro_target: 'HHH', instance_data: '<test>' })
        .and_call_original
      subject.new(client).announce_system('token', nil, '<test>')
    end

    it 'sets namespace data in payload' do
      namespace = 'SMT namespace'

      Connection.any_instance.should_receive(:post)
        .with('/connect/subscriptions/systems',
              auth: 'token',
              params: { hostname: 'connect', hwinfo: 'hwinfo', distro_target: 'HHH', namespace: namespace })
        .and_call_original
      subject.new(client).announce_system('token', nil, nil, namespace)
    end

    context :hostname_detected do
      it 'sends a call with hostname' do
        payload = ['/connect/subscriptions/systems', auth: 'token', params: {
          hostname: 'connect', hwinfo: 'hwinfo', distro_target: 'HHH' }
                  ]
        Connection.any_instance.should_receive(:post).with(*payload).and_call_original
        subject.new(client).announce_system('token')
      end
    end

    context :no_hostname do
      it 'sends a call with ip when hostname is nil' do
        Socket.stub(gethostname: nil)
        Socket.stub(ip_address_list: [Addrinfo.ip('192.168.42.42')])
        payload = ['/connect/subscriptions/systems', auth: 'token', params: {
          hostname: '192.168.42.42', hwinfo: 'hwinfo', distro_target: 'HHH' }
                  ]
        Connection.any_instance.should_receive(:post).with(*payload).and_call_original
        subject.new(client).announce_system('token')
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
        Connection.any_instance.should_receive(:get).with('/connect/systems/services', auth: 'basic_auth_string').and_call_original
        subject.new(client).system_services('basic_auth_string')
      end

      it 'holds expected structure' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/services', auth: 'basic_auth_string').and_call_original
        result = subject.new(client).system_services('basic_auth_string').body
        expect(result).to be_kind_of Array
        expect(result.first.keys).to match_array %w{id name product}
      end
    end

    describe :subscriptions do
      before do
        stub_systems_subscriptions_call
      end

      it 'returns returns array of subscriptions known by the system' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/subscriptions', auth: 'basic_auth_string').and_call_original
        subject.new(client).system_subscriptions('basic_auth_string')
      end

      it 'holds expected structure' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/subscriptions', auth: 'basic_auth_string').and_call_original
        result = subject.new(client).system_subscriptions('basic_auth_string').body
        expect(result).to be_kind_of Array

        attr_ary = %w{id regcode name type status starts_at expires_at}
        attr_ary += %w{system_limit systems_count virtual_count product_classes systems product_ids}
        expect(result.first.keys).to eq attr_ary
      end
    end

    describe :activations do
      before do
        stub_systems_activations_call
      end

      it 'returns returns array of subscriptions known by the system' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/activations', auth: 'basic_auth_string').and_call_original
        subject.new(client).system_activations('basic_auth_string')
      end

      it 'holds expected structure' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/activations', auth: 'basic_auth_string').and_call_original
        result = subject.new(client).system_activations('basic_auth_string').body
        expect(result).to be_kind_of Array
        expect(result.first.keys).to eq %w{id regcode type status starts_at expires_at system_id service}
      end
    end
  end

  describe 'activate_product' do
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
      Connection.any_instance.should_receive(:post)
        .with(api_endpoint, auth: system_auth, params: payload)
        .and_call_original
      response = subject.new(client).activate_product(system_auth, product)
      expect(response.body['name']).to eq 'SUSE_Linux_Enterprise_Server_12_x86_64'
    end

    it 'allows to add an optional parameter "email"' do
      email = 'email@domain.com'
      payload[:email] = email
      Connection.any_instance.should_receive(:post)
        .with(api_endpoint, auth: system_auth, params: payload)
      subject.new(client).activate_product(system_auth, product, email)
    end
  end

  describe 'upgrade_product' do
    let(:api_endpoint) { '/connect/systems/products' }
    let(:system_auth) { 'basic_auth_mock' }
    let(:product) { Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64', release_type: 'aaaa') }
    let(:openstruct_product) { product.to_openstruct }

    it 'calls ConnectAPI with basic auth and params and receives a JSON in return' do
      expect_any_instance_of(Connection).to receive(:put).with(api_endpoint, auth: system_auth, params: openstruct_product.to_params)
      subject.new(client).upgrade_product(system_auth, openstruct_product)
    end
  end

  describe '.downgrade_product' do
    let(:system_auth) { 'basic_auth_mock' }
    let(:product) { Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64', release_type: 'aaaa') }

    it 'is an alias method for upgrade_product' do
      expect(subject.new(client)).to respond_to(:downgrade_product)
    end

    it 'is accepts parameters' do
      allow_any_instance_of(Connection).to receive(:put).and_return true
      subject.new(client).downgrade_product(system_auth, product)
    end
  end

  describe '.synchronize' do
    let(:api_endpoint) { '/connect/systems/products/synchronize' }
    let(:system_auth) { 'basic_auth_mock' }
    let(:products) { [SUSE::Connect::Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64', release_type: nil).to_h] }
    let(:openstruct_product) { product.to_openstruct }

    it 'syncs activated system products with SCC' do
      expect_any_instance_of(Connection).to receive(:post).with(api_endpoint, auth: system_auth, params: products)
      subject.new(client).synchronize(system_auth, products)
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
      Connection.any_instance.should_receive(:get)
        .with(*payload)
        .and_call_original
      subject.new(client).show_product('Basic: encodedgibberish', product)
    end

    it 'responds with proper status code' do
      response = subject.new(client).show_product('Basic: encodedgibberish', product)
      expect(response.code).to eq 200
    end

    it 'returns array of extensions' do
      body = subject.new(client).show_product('Basic: encodedgibberish', product).body
      expect(body).to be_kind_of Hash
    end
  end

  describe '#system_migrations' do
    context 'with a non-empty response' do
      before do
        stub_system_migrations_call
      end

      let(:products) do
        [
          Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64', release_type: 'HP-CNB'),
          Remote::Product.new(identifier: 'SUSE-Cloud', version: '7', arch: 'x86_64', release_type: nil)
        ]
      end

      let(:openstruct_products) { products.map(&:to_openstruct) }
      let(:query) { { installed_products: openstruct_products.map(&:to_params) } }

      it 'is authenticated via basic auth' do
        payload = [
          '/connect/systems/products/migrations',
          auth: 'Basic: encodedgibberish',
          params: query
        ]
        expect_any_instance_of(Connection).to receive(:post)
          .with(*payload)
          .and_call_original

        subject.new(client).system_migrations('Basic: encodedgibberish', openstruct_products)
      end

      it 'responds with proper status code' do
        response = subject.new(client).system_migrations('Basic: encodedgibberish', openstruct_products)

        expect(response.code).to eq 200
      end

      it 'returns array of arrays of product hashes' do
        body = subject.new(client).system_migrations('Basic: encodedgibberish', openstruct_products).body

        expect(body.first).to include('identifier' => 'SLES', 'version' => '12.1', 'arch' => 'x86_64', 'release_type' => 'HP-CNB')
        expect(body.first).to include('identifier' => 'SUSE-Cloud', 'version' => '8', 'arch' => 'x86_64', 'release_type' => nil)
      end
    end

    context 'with an empty response' do
      before do
        stub_empty_system_migrations_call
      end

      let(:products) { [Remote::Product.new(identifier: 'SLES', version: 'not-upgradeable', arch: 'x86_64', release_type: nil)] }
      let(:openstruct_products) { products.map(&:to_openstruct) }

      it 'returns an empty array' do
        body = subject.new(client).system_migrations('Basic: encodedgibberish', openstruct_products).body

        expect(body).to match_array([])
      end
    end
  end

  describe 'deregister' do
    before do
      stub_deregister_call
    end

    it 'is authenticated via basic auth' do
      payload = [
        '/connect/systems',
        auth: 'Basic: encodedgibberish'
      ]

      Connection.any_instance.should_receive(:delete)
        .with(*payload)
        .and_call_original

      subject.new(client).deregister('Basic: encodedgibberish')
    end

    it 'responds with proper status code' do
      response = subject.new(client).deregister('Basic: encodedgibberish')
      expect(response.code).to eq 204
    end

    it 'returns empty body' do
      body = subject.new(client).deregister('Basic: encodedgibberish').body
      expect(body).to be_nil
    end
  end

  describe 'update_system' do
    before do
      stub_update_call
      System.stub(hostname: 'connect')
      System.stub(hwinfo: 'hwinfo')
      Zypper.stub(distro_target: 'openSUSE-4.1-x86_64')
    end

    it 'is authenticated via basic auth' do
      payload = [
        '/connect/systems',
        auth: 'Basic: encodedgibberish', params: { hostname: 'connect', hwinfo: 'hwinfo',
                                                   distro_target: 'openSUSE-4.1-x86_64' }
      ]
      Connection.any_instance.should_receive(:put).with(*payload).and_call_original
      subject.new(client).update_system('Basic: encodedgibberish')
    end

    it 'responds with proper status code' do
      response = subject.new(client).update_system('Basic: encodedgibberish')
      expect(response.code).to eq 204
    end

    it 'returns empty body' do
      body = subject.new(client).update_system('Basic: encodedgibberish').body
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

      Connection.any_instance.should_receive(:put).with(*payload).and_call_original
      subject.new(client).update_system('Basic: encodedgibberish', nil, nil, namespace)
    end
  end
end
