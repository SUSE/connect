require 'spec_helper'

describe SUSE::Connect::YaST do
  subject { SUSE::Connect::YaST }

  describe 'YaST CONSTANTS' do
    it 'checks the constants definition and their values' do
      expect(subject::DEFAULT_CONFIG_FILE).to eq SUSE::Connect::Config::DEFAULT_CONFIG_FILE
      expect(subject::DEFAULT_URL).to eq SUSE::Connect::Config::DEFAULT_URL
      expect(subject::DEFAULT_CREDENTIALS_DIR).to eq SUSE::Connect::Credentials::DEFAULT_CREDENTIALS_DIR
      expect(subject::GLOBAL_CREDENTIALS_FILE).to eq SUSE::Connect::Credentials::GLOBAL_CREDENTIALS_FILE
      expect(subject::SERVER_CERT_FILE).to eq SUSE::Connect::SSLCertificate::SERVER_CERT_FILE
      expect(subject::UPDATE_CERTIFICATES).to eq SUSE::Connect::SSLCertificate::UPDATE_CERTIFICATES
    end
  end

  describe '.announce_system' do
    let(:params) { [{}, 'sles12-x86_64'] }
    before { Client.any_instance.stub :announce_system }

    it 'calls announce_system on an instance of Client' do
      Client.any_instance.should_receive(:announce_system)
      subject.announce_system({}, nil)
    end

    it 'passes distro_target parameter to announce' do
      Client.any_instance.should_receive(:announce_system).with(params.last)
      subject.announce_system(*params)
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      Client.any_instance.should_receive(:announce_system)
      subject.announce_system(*params)
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      Client.any_instance.should_receive(:announce_system)
      subject.announce_system
    end
  end

  describe '.update_system' do
    before { Client.any_instance.stub :update_system }

    it 'calls update_system on an instance of Client' do
      Client.any_instance.should_receive(:update_system)
      subject.update_system
    end

    it 'forwards distro_target parameter to client' do
      Client.any_instance.should_receive(:update_system).with('my-distro-target')
      subject.update_system({}, 'my-distro-target')
    end

    it 'uses client params' do
      expect_any_instance_of(SUSE::Connect::Config)
      subject.update_system(:language => 'de')
    end
  end

  describe '.activate_product' do
    let(:client_params) { { token: 'regcode' } }
    let(:product) { Remote::Product.new(identifier: 'win95') }
    let(:openstruct_product) { product.to_openstruct }
    let(:email) { 'foo@bar.zer' }

    it 'calls activate_product on an instance of Client' do
      expect_any_instance_of(Client).to receive(:activate_product)
      subject.activate_product(nil)
    end

    it 'forwards all params to an instance of Client' do
      expect(Client).to receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      expect_any_instance_of(SUSE::Connect::Config).to receive(:merge!).with(client_params).and_call_original
      expect_any_instance_of(Client).to receive(:activate_product)

      subject.activate_product(*[openstruct_product, client_params, email])
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      expect(Client).to receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      expect_any_instance_of(Client).to receive(:activate_product)

      subject.activate_product(nil)
    end

    it 'uses product_ident and email as parameter for Client#activate_product' do
      expect(Client).to receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      expect_any_instance_of(Client).to receive(:activate_product).with(openstruct_product, email)

      subject.activate_product(*[openstruct_product, client_params, email])
    end
  end

  describe '.upgrade_product' do
    let(:product) { Remote::Product.new(identifier: 'win98') }
    let(:openstruct_product) { product.to_openstruct }
    let(:client_params) { { :foo => 'oink' } }

    before { allow_any_instance_of(Client).to receive(:upgrade_product) }

    it 'calls upgrade_product on an instance of Client' do
      expect_any_instance_of(Client).to receive :upgrade_product
      subject.upgrade_product(openstruct_product)
    end

    it 'forwards all params to an instance of Client' do
      expect(Client).to receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      expect_any_instance_of(SUSE::Connect::Config).to receive(:merge!).with(client_params).and_call_original
      subject.upgrade_product openstruct_product, client_params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      expect(Client).to receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      subject.upgrade_product openstruct_product
    end

    it 'forwards product_ident to Client#upgrade_product' do
      expect_any_instance_of(Client).to receive(:upgrade_product).with(openstruct_product)
      subject.upgrade_product openstruct_product
    end
  end

  describe '.downgrade_product' do
    it 'is an alias method for upgrade_product' do
      expect(subject).to respond_to(:downgrade_product)
    end
  end

  describe '.synchronize' do
    let(:client_params) { {} }
    let(:products) { [{ identifier: 'SLES', version: '12', arch: 'x86_64', release_type: nil }] }
    let(:config) { SUSE::Connect::Config.new }
    before { allow_any_instance_of(Client).to receive(:upgrade_product) }

    it 'calls synchronize on an instance of Client' do
      expect_any_instance_of(Client).to receive(:synchronize).with(products)
      subject.synchronize(products, client_params)
    end
  end

  describe '.credentials' do
    let(:login) { 'login' }
    let(:password) { 'password' }
    let(:system_credentials) { Credentials.new(login, password, subject::GLOBAL_CREDENTIALS_FILE) }

    context 'with no arguments' do
      it 'reads system credentials file' do
        expect(Credentials).to receive(:read).with(subject::GLOBAL_CREDENTIALS_FILE).and_return(system_credentials)
        subject.credentials
      end
    end

    context 'with credentials_file argument' do
      it 'reads credentials from given path' do
        expect(Credentials).to receive(:read).with('/tmp/credentials').and_return(system_credentials)
        subject.credentials('/tmp/credentials')
      end
    end

    it 'returns an OpenStruct instance' do
      expect(Credentials).to receive(:read).with(subject::GLOBAL_CREDENTIALS_FILE).and_return(system_credentials)
      expect(subject.credentials).to be_kind_of(OpenStruct)
    end
  end

  describe '.create_credentials_file' do
    let(:login) { 'login' }
    let(:password) { 'password' }
    let(:credentials) { Credentials.new(login, password, subject::GLOBAL_CREDENTIALS_FILE) }

    it 'creates credentials file with default parameter' do
      credentials = Credentials.new(login, password, subject::GLOBAL_CREDENTIALS_FILE)

      expect(Credentials).to receive(:new).with(login, password, subject::GLOBAL_CREDENTIALS_FILE).and_return credentials
      expect(credentials).to receive(:write)

      subject.create_credentials_file(login, password)
    end

    it 'creates credentials file with passed parameter' do
      credentials_file = '/tmp/Credentials'
      credentials = Credentials.new(login, password, credentials_file)

      expect(Credentials).to receive(:new).with(login, password, credentials_file).and_return credentials
      expect(credentials).to receive(:write)

      subject.create_credentials_file(login, password, credentials_file)
    end
  end

  describe '.show_product' do
    let(:product) { Remote::Product.new(identifier: 'tango') }
    let(:openstruct_product) { product.to_openstruct }
    let(:client_params) { { foo: 'oink' } }

    it 'calls show_product on an instance of Client' do
      expect_any_instance_of(Client).to receive(:show_product).with(openstruct_product).and_return product
      expect(subject.show_product(product)).to eq openstruct_product
    end

    it 'forwards all params to an instance of Client' do
      config = SUSE::Connect::Config.new.merge!(client_params)

      expect_any_instance_of(SUSE::Connect::Config).to receive(:merge!).with(client_params).and_call_original
      expect(Client).to receive(:new).with(config).and_call_original
      expect_any_instance_of(Client).to receive(:show_product).with(openstruct_product).and_return product

      subject.show_product openstruct_product, client_params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      expect_any_instance_of(SUSE::Connect::Config).to receive(:merge!).with({}).and_call_original
      expect(Client).to receive(:new).with(SUSE::Connect::Config.new).and_call_original
      expect_any_instance_of(Client).to receive(:show_product).with(openstruct_product).and_return product

      subject.show_product openstruct_product
    end

    it 'uses product as parameter for Client#list_products' do
      expect(Client).to receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      expect_any_instance_of(Client).to receive(:show_product).with(openstruct_product).and_return product

      subject.show_product openstruct_product
    end

    it 'returns product as an instance of OpenStruct' do
      expect(Client).to receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      expect_any_instance_of(Client).to receive(:show_product).with(openstruct_product).and_return product

      expect(subject.show_product(openstruct_product)).to be_kind_of(OpenStruct)
    end
  end

  describe '.product_activated?' do
    let(:product) { Remote::Product.new(identifier: 'tango') }
    let(:openstruct_product) { product.to_openstruct }

    it 'returns false if no credentials' do
      expect(System).to receive(:credentials?).and_return(false)
      expect(subject.product_activated?(openstruct_product)).to be false
    end

    it 'checks if the given product is already activated in SCC' do
      expect(System).to receive(:credentials?).and_return(true)
      expect_any_instance_of(Status).to receive(:activated_products).and_return([product])
      expect(subject.product_activated?(openstruct_product)).to be true
    end

    it 'allows to pass a Hash with params to instantiate the client' do
      allow(System).to receive(:credentials?).and_return(true)
      status = double 'status'
      params_hash = { foo: 'bar' }
      allow(status).to receive(:activated_products).and_return([product])
      expect(subject).to receive(:status).with(params_hash).and_return status
      expect(subject.product_activated?(openstruct_product, params_hash)).to be true
    end
  end

  describe '.activated_products' do
    let(:remote_product) { Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64', release_type: 'HP-CNB') }

    it 'returns an array of activated system products' do
      expect_any_instance_of(SUSE::Connect::Status).to receive(:activated_products).and_return([remote_product])
      expect(SUSE::Connect::YaST.activated_products).to match_array([remote_product.to_openstruct])
    end
  end

  describe '.system_migrations' do
    let(:products) do
      [
        Remote::Product.new(:identifier => 'SLES', :version => '12', :arch => 'x86_64', :release_type => 'HP-CNB'),
        Remote::Product.new(:identifier => 'SUSE-Cloud', :version => '7', :arch => 'x86_64', :release_type => nil)
      ]
    end

    let(:openstruct_products) { products.map(&:to_openstruct) }
    let(:migrations) { [products] }
    let(:client_params) { { :foo => 'oink' } }

    it 'calls system_migrations on an instance of Client' do
      expect(Client).to receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      expect_any_instance_of(Client).to receive(:system_migrations).and_return migrations

      subject.system_migrations openstruct_products, client_params
    end

    it 'uses products list as parameter for Client#system_migrations' do
      expect(Client).to receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      expect_any_instance_of(Client).to receive(:system_migrations).with(openstruct_products).and_return migrations

      subject.system_migrations openstruct_products, client_params
    end

    it 'returns the output received from Client' do
      expected_migration = [[Remote::Product.new(identifier: 'SLES')]]

      expect(Client).to receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      expect_any_instance_of(Client).to receive(:system_migrations).with(openstruct_products).and_return(expected_migration)

      actual_migration = subject.system_migrations(openstruct_products, client_params)

      expect(actual_migration).to eq(expected_migration)
    end

    it 'returns an array of arrays with openstruct objects' do
      expect(Client).to receive(:new).with(instance_of(SUSE::Connect::Config)).and_call_original
      expect_any_instance_of(Client).to receive(:system_migrations).with(products).and_return(migrations)
      migrations = subject.system_migrations products, client_params

      expect(migrations).to be_kind_of Array
      expect(migrations.first).to be_kind_of Array
      expect(migrations.first.first).to be_kind_of OpenStruct
    end
  end

  describe '.write_config' do
    let(:params) { { url: 'http://scc.foo.com' } }

    it 'merges passed params into config' do
      params = { url: 'http://smt.local.domain' }
      allow_any_instance_of(SUSE::Connect::Config).to receive(:write!).and_return true
      expect_any_instance_of(SUSE::Connect::Config).to receive(:merge!).with(params).and_call_original
      subject.write_config(params)
    end

    it 'calls write_config on an instance of config' do
      expect_any_instance_of(SUSE::Connect::Config).to receive(:write!)
      subject.write_config
    end
  end

  describe '.import_certificate' do
    it 'calls import certificate method from SSLCertificate class' do
      expect(SSLCertificate).to receive(:import).with(:foo)
      subject.import_certificate(:foo)
    end
  end

  describe '.cert_sha1_fingerprint' do
    it 'calls cert_sha1_fingerprint method from SSLCertificate class' do
      expect(SSLCertificate).to receive(:sha1_fingerprint).with(:foo)
      subject.cert_sha1_fingerprint(:foo)
    end
  end

  describe '.cert_sha256_fingerprint' do
    it 'calls cert_sha256_fingerprint method from SSLCertificate class' do
      expect(SSLCertificate).to receive(:sha256_fingerprint).with(:foo)
      subject.cert_sha256_fingerprint(:foo)
    end
  end

  describe '.status' do
    it 'merges passed parameters with config' do
      params = { insecure: true }
      expect_any_instance_of(SUSE::Connect::Config).to receive(:merge!).with(params)
      allow(Status).to receive(:new)
      subject.status(params)
    end

    it 'assigns new client to status with passed hash' do
      expect(Status).to receive(:new).with(instance_of(SUSE::Connect::Config))
      subject.status(:foo => :bar)
    end
  end
end
