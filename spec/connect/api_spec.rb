require 'spec_helper'

describe SUSE::Connect::Api do

  subject { SUSE::Connect::Api }

  let :client do
    client = double('client')
    client.stub(:url => 'https://example.com')
    client.stub(:options => { :token => 'token-shmocken' })
    client
  end

  describe '.new' do

    it 'require client object' do
      expect { subject.new }.to raise_error ArgumentError
    end

    it 'require client object' do
      expect { subject.new(client) }.not_to raise_error
    end

  end

  describe 'announce_system' do

    before do
      stub_announce_call
      Zypper.stub(:write_base_credentials => true)
      Zypper.stub(:distro_target => 'HHH')
    end

    mock_dry_file

    it 'sends a call with token to api' do
      Zypper.stub(:lookup_product_release => 'HHH')
      Connection.any_instance.should_receive(:post).and_call_original
      subject.new(client).announce_system('token')
    end

    it 'won\'t access Zypper if the optional parameter "distro_target" is set' do
      Zypper.should_receive(:distro_target).never
      Connection.any_instance.should_receive(:post).and_call_original
      subject.new(client).announce_system('token', 'optional_target')
    end

    context :hostname_detected do

      it 'sends a call with hostname' do
        Socket.stub(:gethostname => 'vargan')
        payload = ['/connect/subscriptions/systems', :auth => 'token', :params => {
          :hostname => 'vargan', :distro_target => 'HHH' }
        ]
        Connection.any_instance.should_receive(:post).with(*payload).and_call_original
        subject.new(client).announce_system('token')
      end

    end

    context :no_hostname do

      it 'sends a call with ip' do
        System.stub(:hostname => '192.168.42.42')
        payload = ['/connect/subscriptions/systems', :auth => 'token', :params => {
          :hostname => '192.168.42.42', :distro_target => 'HHH' }
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

  end

  describe 'activate_product' do

    let(:api_endpoint) { '/connect/systems/products' }
    let(:basic_auth) { 'basic_auth_mock' }

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
        .with(api_endpoint, :auth => basic_auth, :params => payload)
        .and_call_original
      response = subject.new(client).activate_product(basic_auth, product)
      response.body['name'].should eq 'SUSE_Linux_Enterprise_Server_12_x86_64'
    end

    it 'allows to add an optional parameter "email"' do
      email = 'email@domain.com'
      payload[:email] = email
      Connection.any_instance.should_receive(:post)
        .with(api_endpoint, :auth => basic_auth, :params => payload)
      subject.new(client).activate_product(basic_auth, product, email)
    end

  end

  describe 'upgrade_product' do

    let(:api_endpoint) { '/connect/systems/products' }
    let(:basic_auth) { 'basic_auth_mock' }

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
      .with(api_endpoint, :auth => basic_auth, :params => payload)
      .and_call_original
      response = subject.new(client).upgrade_product(basic_auth, product)
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
        '/connect/systems/',
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

end
