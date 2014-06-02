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
        subject.new(client).systems_services('basic_auth_string')
      end

      it 'holds expected structure' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/services', :auth => 'basic_auth_string').and_call_original
        result = subject.new(client).systems_services('basic_auth_string').body
        result.should be_kind_of Array
        result.first.keys.should eq %w(id name product)
      end

    end

    describe :subscriptions do

      before do
        stub_systems_subscriptions_call
      end

      it 'returns returns array of subscriptions known by the system' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/subscriptions', :auth => 'basic_auth_string').and_call_original
        subject.new(client).systems_subscriptions('basic_auth_string')
      end

      it 'holds expected structure' do
        Connection.any_instance.should_receive(:get).with('/connect/systems/subscriptions', :auth => 'basic_auth_string').and_call_original
        result = subject.new(client).systems_subscriptions('basic_auth_string').body
        result.should be_kind_of Array
        result.first.keys.should eq %w(id regcode name type status starts_at expires_at system_limit systems_count virtual_count product_classes systems product_ids)
      end

    end

  end

  describe 'activate_product' do

    let(:api_endpoint) { '/connect/systems/products' }
    let(:basic_auth) { 'basic_auth_mock' }

    let(:product) do
      {
        :name    => 'SLES',
        :version => '11-SP2',
        :arch    => 'x86_64',
        :token   => 'token-shmocken'
      }
    end

    let(:payload) do
      {
        :product_ident    => 'SLES',
        :product_version  => '11-SP2',
        :arch             => 'x86_64',
        :release_type     => nil,
        :token            => 'token-shmocken',
        :email            => nil
      }
    end

    it 'calls ConnectAPI with basic auth and params and receives a JSON in return' do
      stub_activate_call
      Connection.any_instance.should_receive(:post)
        .with(api_endpoint, :auth => basic_auth, :params => payload)
        .and_call_original
      response = subject.new(client).activate_product(basic_auth, product)
      response.body['sources'].keys.first.should include('SUSE')
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

    let(:product) do
      {
        :name    => 'SLES',
        :version => '12',
        :arch    => 'x86_64'
      }
    end

    let(:payload) do
      {
        :product_ident    => 'SLES',
        :product_version  => '12',
        :arch             => 'x86_64',
        :release_type     => nil
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

  describe 'products' do

    before do
      stub_products_call
    end

    it 'is public' do
      Connection.any_instance.should_receive(:get).with('/connect/products', :auth => nil).and_call_original
      subject.new(client).products
    end

    it 'respond with proper status code' do
      subject.new(client).products.code.should eq 200
    end

    it 'returns array of products' do
      subject.new(client).products.body.should respond_to(:first)
    end

    it 'conforms with predefined structure' do
      response = subject.new(client).products.body
      # TODO: reuse structure checker from upstream
      response.first['repos'].should be_kind_of Array

      %w{id name distro_target description url tags}.each do |key|
        response.first['repos'].first[key].should_not be_nil
      end

      %w{id zypper_name zypper_version release arch friendly_name product_class repos}.each do |key|
        response.first[key].should_not be_nil
      end

    end

  end

  describe 'products' do

    before do
      stub_addons_call
    end

    it 'is authenticated via basic auth' do
      payload = [
        '/connect/systems/products',
        :auth => 'Basic: encodedgibberish',
        :params => { :product_id => 'rodent' }
      ]
      Connection.any_instance.should_receive(:get)
        .with(*payload)
        .and_call_original
      subject.new(client).addons('Basic: encodedgibberish', :name => 'rodent')
    end

    it 'responds with proper status code' do
      response = subject.new(client).addons('Basic: encodedgibberish', :name => 'rodent')
      response.code.should eq 200
    end

    it 'returns array of extensions' do
      body = subject.new(client).addons('Basic: encodedgibberish', :name => 'rodent').body
      body.should be_kind_of Array
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
