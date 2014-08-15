require 'spec_helper'

describe SUSE::Connect::Client do

  subject { SUSE::Connect::Client.new({}) }
  let(:default_logger) { SUSE::Connect::GlobalLogger.instance.log }
  let(:string_logger) { ::Logger.new(StringIO.new) }

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

      it 'should set insecure flag from options if it was passed via constructor' do
        client = Client.new(:insecure => true)
        expect(client.options[:insecure]).to be true
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
            'url' => 'https://localsmt.domain.local',
            'language' => 'RU'
        )
      end

      it 'should set url to the config URL' do
        expect(subject.url).to eq 'https://localsmt.domain.local'
      end

      it 'should set token to one from config file' do
        expect(subject.options[:token]).to eq 'from_config'
      end

      it 'should set language to one from config file' do
        expect(subject.options[:language]).to eq 'RU'
      end

    end

    context :override_config_file_with_opts do

      subject { Client.new(url: 'https://localsmt.domain.local') }

      before do
        SUSE::Connect::Config.any_instance.stub(:read).and_return(
            'regcode' => 'from_config',
            'url' => 'localhost',
            'language' => 'RU'
        )
      end

      it 'url should be from options, not configfile' do
        expect(subject.url).to eq 'https://localsmt.domain.local'
      end

      it 'should set url in config to that form opts' do
        expect(subject.instance_variable_get(:@config).url).to eq 'https://localsmt.domain.local'
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
        Api.any_instance.should_receive(:announce_system).with(true, optional_target, nil)
        subject.announce_system(optional_target)
      end

      it 'reads instance_data_file and passes content the API' do
        instance_file_path = 'spec/fixtures/instance_data.xml'
        Api.any_instance.should_receive(:announce_system).with(true, nil, File.read(instance_file_path))
        subject.announce_system(nil, instance_file_path)
      end

      it 'fails on unavailable instance_data_file' do
        File.should_receive(:readable?).with('/test').and_return(false)
        expect { subject.announce_system(nil, '/test') }.to raise_error(Errno::EACCES, 'Permission denied - Instance data file not found')
      end

    end

    describe '#update_system' do

      context :direct_connection do

        subject { SUSE::Connect::Client.new({}) }

        before do
          subject.stub(:system_auth => 'auth')
          Api.any_instance.stub(:update_system)
        end

        it 'calls underlying api' do
          Api.any_instance.should_receive(:update_system).with('auth')
          subject.update_system
        end

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

    let(:product_ident) { { :identifier => 'SLES', :version => '12', :arch => 'x86_64' } }

    before do
      api_response = double('api_response')
      api_response.stub(:body => { 'name' => 'kinkat', 'url' => 'kinkaturl', 'product' => {} })
      Api.any_instance.stub(:activate_product => api_response)
      subject.stub(:system_auth => 'secretsecret')
    end

    it 'gets login and password from system' do
      subject.should_receive(:system_auth)
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
      service.name.should eq 'kinkat'
      service.url.should eq 'kinkaturl'
    end

  end

  describe '#upgrade_product' do

    let(:product_ident) { { :identifier => 'SLES', :version => '12', :arch => 'x86_64' } }

    before do
      api_response = double('api_response')
      api_response.stub(:body => { 'name' => 'tongobongo', 'url' => 'tongobongourl', 'product' => {} })
      Api.any_instance.stub(:upgrade_product => api_response)
      subject.stub(:system_auth => 'secretsecret')
    end

    it 'gets login and password from system' do
      subject.should_receive(:system_auth)
      subject.upgrade_product(product_ident)
    end

    it 'calls underlying api with proper parameters' do
      Api.any_instance.should_receive(:upgrade_product).with('secretsecret', product_ident)
      subject.upgrade_product(product_ident)
    end

    it 'returns service object' do
      service = subject.upgrade_product(product_ident)
      service.name.should eq 'tongobongo'
      service.url.should eq 'tongobongourl'
    end

  end

  describe '#register!' do

    before do
      Zypper.stub(:base_product => Zypper::Product.new(:name => 'SLE_BASE'))
      System.stub(:add_service => true)
      Zypper.stub(:write_base_credentials)
      Credentials.any_instance.stub(:write)
      subject.stub(:activate_product)
      subject.stub(:update_system)
    end

    it 'should call announce if system not registered' do
      System.stub(:credentials? => false)
      subject.should_receive(:announce_system)
      subject.register!
    end

    it 'should not call announce but update on api if system registered' do
      System.stub(:credentials? => true)
      subject.should_not_receive(:announce_system)
      subject.should_receive(:update_system)
      subject.register!
    end

    it 'should call activate_product on api' do
      System.stub(:credentials? => true)
      subject.should_receive(:activate_product)
      subject.register!
    end

    it 'writes credentials file' do
      System.stub(:credentials? => false)
      subject.stub(:announce_system => %w{ lg pw })
      Credentials.should_receive(:new).with('lg', 'pw', Credentials::GLOBAL_CREDENTIALS_FILE).and_call_original
      subject.register!
    end

    it 'adds service after product activation' do
      System.stub(:credentials? => true)
      System.should_receive(:add_service)
      subject.register!
    end

    it 'prints message on successful register' do
      product = Zypper::Product.new(name: 'SLES', version: 12, arch: 's390')
      client = Client.new(url: 'http://dummy:42', email: 'asd@asd.de', product: product, filesystem_root: '/test')
      client.stub(:announce_or_update)
      client.stub(:activate_product)
      Zypper.stub(:base_product => product)
      SUSE::Connect::GlobalLogger.instance.log = string_logger

      string_logger.should_receive(:info).with('Registered SLES 12 s390')
      string_logger.should_receive(:info).with('To server: http://dummy:42')
      string_logger.should_receive(:info).with('Using E-Mail: asd@asd.de')
      string_logger.should_receive(:info).with('Rooted at: /test')
      client.register!
      SUSE::Connect::GlobalLogger.instance.log = default_logger
    end

  end

  describe '#show_product' do

    let(:stubbed_response) do
      OpenStruct.new(
        :code => 200,
        :body => { 'name' => 'short_name', 'identifier' => 'text_identifier' },
        :success => true
      )
    end

    let(:product) { Remote::Product.new(:identifier => 'text_identifier')  }

    before do
      subject.stub(:system_auth => 'Basic: encodedstring')
    end

    it 'collects data from api response' do
      subject.api.should_receive(:show_product).with('Basic: encodedstring', product).and_return stubbed_response
      subject.show_product(product)
    end

    it 'returns array of extension products returned from api' do
      subject.api.should_receive(:show_product).with('Basic: encodedstring', product).and_return stubbed_response
      subject.show_product(product).should be_kind_of Remote::Product
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
      subject.stub(:system_auth => 'Basic: encodedstring')
    end

    it 'calls underlying api and removes credentials file' do
      subject.api.should_receive(:deregister).with('Basic: encodedstring').and_return stubbed_response
      subject.deregister!.should be true
    end
  end

  describe '#write_config' do
    subject { Client.new({}) }
    it 'should call write_config on client' do
      subject.instance_variable_get(:@config).should_receive(:write)
      File.stub(:write => 42)
      subject.write_config
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
      subject.stub(:system_auth => 'Basic: encodedstring')
    end

    it 'calls underlying api and removes credentials file' do
      allow(subject.api).to receive(:system_services).with('Basic: encodedstring').and_return stubbed_response
      expect(subject.system_services).to eq stubbed_response
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
      subject.stub(:system_auth => 'Basic: encodedstring')
    end

    it 'calls underlying api and removes credentials file' do
      expect(subject.api).to receive(:system_subscriptions).with('Basic: encodedstring').and_return stubbed_response
      expect(subject.system_subscriptions).to eq stubbed_response
    end
  end

  describe '#systems_activations' do

    let(:stubbed_response) do
      OpenStruct.new(
          :code => 200,
          :body => nil,
          :success => true
      )
    end

    before do
      subject.stub(:system_auth => 'Basic: encodedstring')
    end

    it 'calls underlying api with system_activations call' do
      expect(subject.api).to receive(:system_activations).with('Basic: encodedstring').and_return stubbed_response
      subject.system_activations
    end

  end

end
