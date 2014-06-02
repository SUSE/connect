require 'spec_helper'

describe SUSE::Connect::Client do

  subject { SUSE::Connect::Client.new({}) }

  describe '.new' do

    context :empty_opts do

      it 'should set url to default_url' do
        subject.url.should eq subject.class::DEFAULT_URL
      end

    end

    context :passed_opts do

      subject { Client.new(:url => 'http://dummy:42') }

      let :parsed_uri do
        URI.parse(subject.url)
      end

      it 'should set port to one from options if it was passed via constructor' do
        parsed_uri.port.should eq 42
      end

      it 'should set host to one from options if it was passed via constructor' do
        parsed_uri.host.should eq 'dummy'
      end

      it 'allows to pass arbitrary options' do
        client = Client.new(foo: 'bar')
        expect(client.options[:foo]).to eq 'bar'
      end

    end

    context :from_config do

      subject { Client.new({}) }

      before do
        SUSE::Connect::Config.any_instance.stub(:read).and_return(
          'regcode' => 'from_config',
          'url' => 'localhost',
          'language' => 'RU'
        )
      end

      it 'should set url to the config URL' do
        expect(subject.url).to eq 'localhost'
      end

      it 'should set token to one from config file' do
        expect(subject.options[:token]).to eq 'from_config'
      end

      it 'should set language to one from config file' do
        expect(subject.options[:language]).to eq 'RU'
      end

    end

  end

  describe '#announce_system' do

    context :direct_connection do

      subject { SUSE::Connect::Client.new(:token => 'blabla') }

      before do
        api_response = double('api_response')
        api_response.stub(:body => { 'login' => 'lg', 'password' => 'pw' })
        Api.any_instance.stub(:announce_system => api_response)
        subject.stub(:token_auth => true)
      end

      it 'calls underlying api' do
        Zypper.stub :write_base_credentials
        Api.any_instance.should_receive :announce_system
        subject.announce_system
      end

      it 'passes the optional parameter "distro_target" to the API' do
        optional_target = 'optional_target'
        Api.any_instance.should_receive(:announce_system).with(true, optional_target)
        subject.announce_system(optional_target)
      end

    end

    context :registration_proxy_connection do

      subject { SUSE::Connect::Client.new(:url => 'http://smt.local') }

      before do
        api_response = double('api_response')
        api_response.stub(:body => { 'login' => 'lg', 'password' => 'pw' })
        Zypper.stub(:write_base_credentials).with('lg', 'pw')
        Api.any_instance.stub(:announce_system => api_response)
        subject.stub(:token_auth => true)
      end

      it 'not raising exception if regcode is absent' do
        expect { subject.announce_system }.not_to raise_error
      end

      it 'calls underlying api' do
        Zypper.stub :write_base_credentials
        Api.any_instance.should_receive :announce_system
        subject.announce_system
      end

    end

  end

  describe '#activate_product' do

    let(:product_ident) { { :name => 'SLES', :version => '12', :arch => 'x86_64' } }

    before do
      api_response = double('api_response')
      api_response.stub(:body => { 'sources' => { :foo => 'bar' }, 'enabled' => [:foo], 'norefresh' => [:foo] })
      Api.any_instance.stub(:activate_product => api_response)
      subject.stub(:basic_auth => 'secretsecret')
    end

    it 'gets login and password from system' do
      subject.should_receive(:basic_auth)
      subject.activate_product(product_ident)
    end

    it 'calls underlying api with proper parameters' do
      Api.any_instance.should_receive(:activate_product).with('secretsecret', product_ident, nil)
      subject.activate_product(product_ident)
    end

    it 'allows to pass an optional parameter "email"' do
      email = 'email@domain.com'
      Api.any_instance.should_receive(:activate_product).with('secretsecret', product_ident, email)
      subject.activate_product(product_ident, email)
    end

    it 'returns service object' do
      service = subject.activate_product(product_ident)
      service.sources.first.name.should eq :foo
      service.enabled.should eq [:foo]
    end

  end

  describe '#upgrade_product' do

    let(:product_ident) { { :name => 'SLES', :version => '12', :arch => 'x86_64' } }

    before do
      api_response = double('api_response')
      api_response.stub(:body => { 'sources' => { :foo => 'bar' }, 'enabled' => [:foo], 'norefresh' => [:foo] })
      Api.any_instance.stub(:upgrade_product => api_response)
      subject.stub(:basic_auth => 'secretsecret')
    end

    it 'gets login and password from system' do
      subject.should_receive(:basic_auth)
      subject.upgrade_product(product_ident)
    end

    it 'calls underlying api with proper parameters' do
      Api.any_instance.should_receive(:upgrade_product).with('secretsecret', product_ident)
      subject.upgrade_product(product_ident)
    end

    it 'returns service object' do
      service = subject.upgrade_product(product_ident)
      service.sources.first.name.should eq :foo
      service.enabled.should eq [:foo]
    end

  end

  describe '#register!' do

    before do
      Zypper.stub(:base_product => { :name => 'SLE_BASE' })
      System.stub(:add_service => true)
      Zypper.stub(:write_base_credentials)
      Credentials.any_instance.stub(:write)
      subject.stub(:activate_product)
      subject.class.any_instance.stub(:basic_auth => true)
      subject.class.any_instance.stub(:token_auth => true)
    end

    it 'should call announce if system not registered' do
      System.stub(:registered? => false)
      subject.should_receive(:announce_system)
      subject.register!
    end

    it 'should not call announce on api if system registered' do
      System.stub(:registered? => true)
      subject.should_not_receive(:announce_system)
      subject.register!
    end

    it 'should call activate_product on api' do
      System.stub(:registered? => true)
      subject.should_receive(:activate_product)
      subject.register!
    end

    it 'writes credentials file' do
      System.stub(:registered? => false)
      subject.stub(:announce_system => %w{ lg pw })
      Credentials.should_receive(:new).with('lg', 'pw', Credentials::GLOBAL_CREDENTIALS_FILE).and_call_original
      subject.register!
    end

    it 'adds service after product activation' do
      System.stub(:registered? => true)
      System.should_receive(:add_service)
      subject.register!
    end

  end

  describe '#list_products' do

    let(:stubbed_response) do
      OpenStruct.new(
        :code => 200,
        :body => [{ 'name' => 'short_name', 'zypper_name' => 'zypper_name' }],
        :success => true
      )
    end

    before do
      subject.stub(:basic_auth => 'Basic: encodedstring')
    end

    it 'collects data from api response' do
      subject.api.should_receive(:addons).with('Basic: encodedstring', 'SLES').and_return stubbed_response
      subject.list_products('SLES')
    end

    it 'returns array of extension products returned from api' do
      subject.api.should_receive(:addons).with('Basic: encodedstring', 'SLES').and_return stubbed_response
      subject.list_products('SLES').first.should be_kind_of SUSE::Connect::Product
    end

  end

  describe '#deregister!' do
    let(:stubbed_response) do
      OpenStruct.new(
        :code => 204,
        :body => nil,
        :success => true
      )
    end

    before do
      System.should_receive(:remove_credentials).and_return(true)
      subject.stub(:basic_auth => 'Basic: encodedstring')
    end

    it 'calls underlying api and removes credentials file' do
      subject.api.should_receive(:deregister).with('Basic: encodedstring').and_return stubbed_response
      subject.deregister!.should be_true
    end
  end

  describe '#systems_services' do
    let(:stubbed_response) do
      OpenStruct.new(
          :code => 204,
          :body => nil,
          :success => true
      )
    end

    before do
      subject.stub(:basic_auth => 'Basic: encodedstring')
    end

    it 'calls underlying api and removes credentials file' do
      allow(subject.api).to receive(:systems_services).with('Basic: encodedstring').and_return stubbed_response
      expect(subject.systems_services).to be_true
    end
  end

  describe '#systems_subscriptions' do
    let(:stubbed_response) do
      OpenStruct.new(
          :code => 204,
          :body => nil,
          :success => true
      )
    end

    before do
      subject.stub(:basic_auth => 'Basic: encodedstring')
    end

    it 'calls underlying api and removes credentials file' do
      expect(subject.api).to receive(:systems_subscriptions).with('Basic: encodedstring').and_return stubbed_response
      expect(subject.systems_subscriptions).to be_true
    end
  end

  describe '#status' do
    let(:stubbed_response) do
      OpenStruct.new(
          :code => 204,
          :body => nil,
          :success => true
      )
    end

    before do
      subject.stub(:basic_auth => 'Basic: encodedstring')
    end

    it 'calls underlying api and removes credentials file' do
      expect(Status).to receive(:new).with(subject).and_return(true)
      subject.status
    end
  end

end
