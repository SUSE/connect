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
           token: 'token-shmocken',
           yast_version: nil
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
      Socket.stub(:gethostname => 'connect')
      System.stub(:hwinfo => 'hwinfo')
      Zypper.stub(:write_base_credentials => true)
      Zypper.stub(:distro_target => 'HHH')
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
              :auth => 'token',
              :params => { :hostname => 'connect', :hwinfo => 'hwinfo', :distro_target => 'HHH', :instance_data => '<test>' })
        .and_call_original
      subject.new(client).announce_system('token', nil, '<test>')
    end

    context :hostname_detected do

      it 'sends a call with hostname' do
        payload = ['/connect/subscriptions/systems', :auth => 'token', :params => {
          :hostname => 'connect', :hwinfo => 'hwinfo', :distro_target => 'HHH' }
        ]
        Connection.any_instance.should_receive(:post).with(*payload).and_call_original
        subject.new(client).announce_system('token')
      end

    end

    context :no_hostname do

      it 'sends a call with ip when hostname is nil' do
        Socket.stub(:gethostname => nil)
        Socket.stub(:ip_address_list => [Addrinfo.ip('192.168.42.42')])
        payload = ['/connect/subscriptions/systems', :auth => 'token', :params => {
          :hostname => '192.168.42.42', :hwinfo => 'hwinfo', :distro_target => 'HHH' }
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
        Connection.any_instance.should_receive(:get).with('/connect/systems/services', :auth => 'basic_auth_string').and_call_original
        subject.new(client).system_services('basic_auth_string')
      end

      it 'holds expected structure' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/services', :auth => 'basic_auth_string').and_call_original
        result = subject.new(client).system_services('basic_auth_string').body
        result.should be_kind_of Array
        result.first.keys.should eq %w{id name product}
      end

    end

    describe :subscriptions do

      before do
        stub_systems_subscriptions_call
      end

      it 'returns returns array of subscriptions known by the system' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/subscriptions', :auth => 'basic_auth_string').and_call_original
        subject.new(client).system_subscriptions('basic_auth_string')
      end

      it 'holds expected structure' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/subscriptions', :auth => 'basic_auth_string').and_call_original
        result = subject.new(client).system_subscriptions('basic_auth_string').body
        result.should be_kind_of Array
        attr_ary = %w{id regcode name type status starts_at expires_at}
        attr_ary += %w{system_limit systems_count virtual_count product_classes systems product_ids}
        result.first.keys.should eq attr_ary
      end

    end

    describe :activations do

      before do
        stub_systems_activations_call
      end

      it 'returns returns array of subscriptions known by the system' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/activations', :auth => 'basic_auth_string').and_call_original
        subject.new(client).system_activations('basic_auth_string')
      end

      it 'holds expected structure' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/activations', :auth => 'basic_auth_string').and_call_original
        result = subject.new(client).system_activations('basic_auth_string').body
        result.should be_kind_of Array
        attr_ary = %w{id regcode type status starts_at expires_at system_id service}
        expect(result.first.keys).to eq attr_ary
      end

    end

  end

  describe 'activate_product' do

    let(:api_endpoint) { '/connect/systems/products' }
    let(:system_auth) { 'basic_auth_mock' }

    let(:product) { Remote::Product.new(:identifier => 'SLES', :version => '11-SP2', :arch => 'x86_64', :token => 'token-shmocken') }

    let(:payload) do
      {
        :identifier   => 'SLES',
        :version      => '11-SP2',
        :arch         => 'x86_64',
        :release_type => nil,
        :token        => 'token-shmocken',
        :email        => nil
      }
    end

    it 'calls ConnectAPI with basic auth and params and receives a JSON in return (use proper webmock)' do
      stub_activate_call
      Connection.any_instance.should_receive(:post)
        .with(api_endpoint, :auth => system_auth, :params => payload)
        .and_call_original
      response = subject.new(client).activate_product(system_auth, product)
      response.body['name'].should eq 'SUSE_Linux_Enterprise_Server_12_x86_64'
    end

    it 'allows to add an optional parameter "email"' do
      email = 'email@domain.com'
      payload[:email] = email
      Connection.any_instance.should_receive(:post)
        .with(api_endpoint, :auth => system_auth, :params => payload)
      subject.new(client).activate_product(system_auth, product, email)
    end

  end

  describe 'upgrade_product' do

    let(:api_endpoint) { '/connect/systems/products' }
    let(:system_auth) { 'basic_auth_mock' }

    let(:product) { Remote::Product.new(:identifier => 'SLES', :version => '12', :arch => 'x86_64') }

    let(:payload) do
      {
        :identifier   => 'SLES',
        :version      => '12',
        :arch         => 'x86_64',
        :release_type => nil
      }
    end

    it 'calls ConnectAPI with basic auth and params and receives a JSON in return' do
      stub_upgrade_call
      Connection.any_instance.should_receive(:put)
      .with(api_endpoint, :auth => system_auth, :params => payload)
      .and_call_original
      response = subject.new(client).upgrade_product(system_auth, product)
      response.body['sources'].keys.first.should include('SUSE')
    end

  end

  describe 'system products' do

    before do
      stub_show_product_call
    end

    let(:product) { Remote::Product.new(:identifier => 'rodent', :version => 'good', :arch => 'z42', :release_type => 'foo') }
    let(:query) { { :identifier => product.identifier, :version => product.version, :arch => product.arch, :release_type => 'foo' } }

    it 'is authenticated via basic auth' do
      payload = [
        '/connect/systems/products',
        :auth => 'Basic: encodedgibberish',
        :params => query
      ]
      Connection.any_instance.should_receive(:get)
        .with(*payload)
        .and_call_original
      subject.new(client).show_product('Basic: encodedgibberish', product)
    end

    it 'responds with proper status code' do
      response = subject.new(client).show_product('Basic: encodedgibberish', product)
      response.code.should eq 200
    end

    it 'returns array of extensions' do
      body = subject.new(client).show_product('Basic: encodedgibberish', product).body
      body.should be_kind_of Hash
    end

  end

  describe 'deregister' do

    before do
      stub_deregister_call
    end

    it 'is authenticated via basic auth' do
      payload = [
        '/connect/systems',
        :auth => 'Basic: encodedgibberish'
      ]

      Connection.any_instance.should_receive(:delete)
        .with(*payload)
        .and_call_original

      subject.new(client).deregister('Basic: encodedgibberish')
    end

    it 'responds with proper status code' do
      response = subject.new(client).deregister('Basic: encodedgibberish')
      response.code.should eq 204
    end

    it 'returns empty body' do
      body = subject.new(client).deregister('Basic: encodedgibberish').body
      body.should be_nil
    end
  end

  describe 'update' do

    before do
      stub_update_call
      System.stub(:hostname => 'connect')
      System.stub(:hwinfo => 'hwinfo')
      Zypper.stub(:distro_target => 'openSUSE-4.1-x86_64')
    end

    it 'is authenticated via basic auth' do
      payload = [
        '/connect/systems',
        :auth => 'Basic: encodedgibberish', :params => { :hostname => 'connect', :hwinfo => 'hwinfo',
                                                         :distro_target => 'openSUSE-4.1-x86_64' }
      ]
      Connection.any_instance.should_receive(:put).with(*payload).and_call_original
      subject.new(client).update_system('Basic: encodedgibberish')
    end

    it 'responds with proper status code' do
      response = subject.new(client).update_system('Basic: encodedgibberish')
      response.code.should eq 204
    end

    it 'returns empty body' do
      body = subject.new(client).update_system('Basic: encodedgibberish').body
      body.should be_nil
    end
  end

end
