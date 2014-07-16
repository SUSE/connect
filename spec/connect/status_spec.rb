require 'spec_helper'

describe SUSE::Connect::Status do

  subject { described_class }

  before do
    reset_class_variables Status
  end

  describe '.client' do

    it 'sets client class variable' do
      allow(Client).to receive(:new).and_return(:baz)
      expect(described_class.client).to eq :baz
    end

    it 'memoizes client class variable to avoid reinstantiation' do
      expect(described_class.client).to be subject.client
    end

  end

  describe '.activated_products' do

    it 'memoizes activated_products by the first call' do
      allow(Status).to receive(:products_from_activations).and_return(:foobazbar)
      expect(Status.activated_products).to be Status.activated_products
    end

    it 'calls products_from_services from Status class' do
      expect(Status).to receive(:products_from_activations)
      Status.activated_products
    end

  end

  describe '.installed_products' do

    it 'memoizes installed_products by the first call' do
      allow(Status).to receive(:products_from_zypper).and_return(:barbarbaz)
      expect(Status.installed_products).to be Status.installed_products
    end

    it 'calls products_from_zypper from Status class' do
      expect(Status).to receive(:products_from_activations)
      Status.activated_products
    end

  end

  describe '.known_activations' do

    it 'memoizes known_activations by the first call' do
      allow(Status).to receive(:activations_from_server).and_return(:superdo)
      expect(Status.activations).to be Status.activations
    end

    it 'calls products_from_zypper from Status class' do
      expect(Status).to receive(:activations_from_server)
      Status.activations
    end

  end

  describe '.print_product_statuses' do

    describe 'text format' do

      it 'reads template from erb file' do
        expect(File).to receive(:read).with(include('templates/product_statuses.text.erb')).and_return '111'
        allow(described_class).to receive(:puts)
        described_class.print_product_statuses
      end

      it 'builds proper erb entity' do
        allow(File).to receive(:read).and_return('blaherbfile')
        allow(described_class).to receive(:puts)
        mock_erb = double('mock_erb')
        allow(mock_erb).to receive(:result)
        expect(ERB).to receive(:new).with('blaherbfile', 0, '-<>').and_return mock_erb
        described_class.print_product_statuses
      end

      it 'outputs the result of parsing erb with bindings' do
        allow(File).to receive(:read).and_return('blaherbfile')
        expect(described_class).to receive(:puts).with('parsed erb output')
        mock_erb = double('mock_erb')
        allow(mock_erb).to receive(:result).and_return('parsed erb output')
        allow(ERB).to receive(:new).with('blaherbfile', 0, '-<>').and_return mock_erb
        described_class.print_product_statuses
      end

    end

    describe 'json format' do

      it 'outputs the system status in json format' do
        status = Zypper::ProductStatus.new(Zypper::Product.new({}))
        status.stub(:registration_status) { 'test' }
        status.stub(:remote_product) { true }
        status.stub_chain(:remote_product, :free).and_return(false)
        activation = SUSE::Connect::Remote::Activation.new('service' => { 'product' => {} })
        status.stub(:related_activation).and_return(activation)

        expect(described_class).to receive(:product_statuses).and_return [status]
        expect(described_class).to receive(:puts)
        described_class.print_product_statuses(:json)
      end

    end

    it 'errors out on unsupported format' do
      expect { described_class.print_product_statuses(:xml) }.to raise_error
    end

  end

  describe 'private' do

    describe '?product_statuses' do

      it 'wrapping each installed product into Zypper::ProductStatus' do
        allow(described_class).to receive(:installed_products).and_return([:f, :a, :b])
        expect(Zypper::ProductStatus).to receive(:new).with(:f)
        expect(Zypper::ProductStatus).to receive(:new).with(:a)
        expect(Zypper::ProductStatus).to receive(:new).with(:b)
        described_class.send(:product_statuses)
      end

    end

    describe '?products_from_zypper' do

      it 'uses zypper output to collect info' do
        Zypper.stub_chain(:installed_products).and_return [1, 2, 3]
        expect(subject.send(:products_from_zypper)).to eq [1, 2, 3]
      end

    end

    describe '?products_from_activations' do

      it 'uses clients response to collect info' do
        fake_client = double('client')
        allow(Client).to receive(:new).and_return(fake_client)
        fake_client.stub_chain(:system_activations, :body, :map).and_return [1, 2, 3]
        expect(subject.send(:products_from_activations)).to eq [1, 2, 3]
      end

    end

    describe '?activations_from_server' do

      it 'mapping system_activations response to Remote::Activations' do
        described_class.stub(:system_activations).and_return [1, 2, 3]
        expect(Remote::Activation).to receive(:new).with(1)
        expect(Remote::Activation).to receive(:new).with(2)
        expect(Remote::Activation).to receive(:new).with(3)
        described_class.send(:activations_from_server)
      end

    end

  end

end
