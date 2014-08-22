require 'spec_helper'

describe SUSE::Connect::YaST do

  subject { SUSE::Connect::YaST }

  describe '#announce_system' do

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
      Client.should_receive(:new).with(params.first).and_call_original
      Client.any_instance.should_receive(:announce_system)
      subject.announce_system(*params)
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_call_original
      Client.any_instance.should_receive(:announce_system)
      subject.announce_system
    end

  end

  describe '#update_system' do

    before { Client.any_instance.stub :update_system }

    it 'calls update_system on an instance of Client' do
      Client.any_instance.should_receive(:update_system)
      subject.update_system
    end

  end

  describe '#activate_product' do

    let(:client_params) { { token: 'regcode' } }
    let(:product) { Remote::Product.new(identifier: 'win95') }
    let(:email) { 'foo@bar.zer' }

    before { Client.any_instance.stub :activate_product }

    it 'calls activate_product on an instance of Client' do
      Client.any_instance.should_receive(:activate_product)
      subject.activate_product(nil)
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(client_params).and_call_original
      Client.any_instance.should_receive(:activate_product)
      subject.activate_product(*[product, client_params, email])
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_call_original
      Client.any_instance.should_receive(:activate_product)
      subject.activate_product(nil)
    end

    it 'uses product_ident and email as parameter for Client#activate_product' do
      Client.should_receive(:new).with(client_params).and_call_original
      Client.any_instance.should_receive(:activate_product).with(product, email)
      subject.activate_product(*[product, client_params, email])
    end

  end

  describe '#upgrade_product' do

    let(:product) { Remote::Product.new(identifier: 'win98') }
    let(:client_params) { { :foo => 'oink' } }

    before { Client.any_instance.stub :upgrade_product }

    it 'calls upgrade_product on an instance of Client' do
      Client.any_instance.should_receive :upgrade_product
      subject.upgrade_product(product)
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(client_params).and_call_original
      subject.upgrade_product product, client_params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_call_original
      subject.upgrade_product product
    end

    it 'forwards product_ident to Client#upgrade_product' do
      Client.any_instance.should_receive(:upgrade_product).with(product)
      subject.upgrade_product product
    end

  end

  describe '#show_product' do

    let(:product) { Remote::Product.new(identifier: 'tango') }
    let(:client_params) { { :foo => 'oink' } }

    before { Client.any_instance.stub :show_product }

    it 'calls list_products on an instance of Client' do
      Client.any_instance.should_receive(:show_product)
      subject.show_product product
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(client_params).and_call_original
      Client.any_instance.should_receive(:show_product)
      subject.show_product product, client_params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_call_original
      Client.any_instance.should_receive(:show_product)
      subject.show_product product
    end

    it 'uses product as parameter for Client#list_products' do
      Client.should_receive(:new).with({}).and_call_original
      Client.any_instance.should_receive(:show_product).with(product)
      subject.show_product product
    end

  end

  describe '#product_activated?' do
    let(:product) { Remote::Product.new(identifier: 'tango') }

    it 'returns false if no credentials' do
      expect(System).to receive(:credentials?).and_return(false)
      expect(subject.product_activated?(product)).to be false
    end

    it 'checks if the given product is already activated in SCC' do
      expect(System).to receive(:credentials?).and_return(true)
      expect(Status).to receive(:activated_products).and_return([product])
      expect(subject.product_activated?(product)).to be true
    end

    it 'allows to pass a Hash with params to instantiate the client' do
      expect(System).to receive(:credentials?).and_return(true)
      client = double 'status'
      params_hash = { foo: 'bar' }
      expect(Client).to receive(:new).with(params_hash).and_return(client)
      expect(Status).to receive(:client=).with(client)
      expect(Status).to receive(:activated_products).and_return([product])
      expect(subject.product_activated?(product, params_hash)).to be true
    end

  end

  describe '#write_config' do
    let(:params) { { url: 'http://scc.foo.com' } }

    it 'calls write_config on an instance of Client' do
      Client.any_instance.should_receive(:write_config)
      subject.write_config params
    end
  end

  describe '#import_certificate' do

    it 'calls import certificate method from SSLCertificate class' do
      expect(SSLCertificate).to receive(:import).with(:foo)
      subject.import_certificate(:foo)
    end

  end

  describe '#cert_sha1_fingerprint' do

    it 'calls cert_sha1_fingerprint method from SSLCertificate class' do
      expect(SSLCertificate).to receive(:sha1_fingerprint).with(:foo)
      subject.cert_sha1_fingerprint(:foo)
    end

  end

  describe '#cert_sha256_fingerprint' do

    it 'calls cert_sha256_fingerprint method from SSLCertificate class' do
      expect(SSLCertificate).to receive(:sha256_fingerprint).with(:foo)
      subject.cert_sha256_fingerprint(:foo)
    end

  end

  describe '#status' do

    it 'assigns new client to status with passed hash' do
      expect(Client).to receive(:new).with(:foo => :bar)
      subject.status(:foo => :bar)
    end

  end

end
