require 'spec_helper'

describe SUSE::Connect::Status do
  let(:client_double) { double('client') }

  subject do
    described_class.new(double('config'))
  end

  before do
    allow(Client).to receive(:new).and_return(client_double)
  end

  describe '#client' do
    it 'returns the client' do
      expect(subject.client).to eq client_double
    end
  end

  describe '#activated_products' do
    it 'memoizes activated_products by the first call' do
      allow(subject).to receive(:products_from_activations).and_return(:foobazbar)
      expect(subject.activated_products).to be subject.activated_products
    end

    it 'calls products_from_services from Status class' do
      expect(subject).to receive(:products_from_activations)
      subject.activated_products
    end
  end

  describe '#installed_products' do
    it 'memoizes installed_products by the first call' do
      allow(subject).to receive(:products_from_zypper).and_return(:barbarbaz)
      expect(subject.installed_products).to be subject.installed_products
    end

    it 'calls products_from_zypper from Status class' do
      expect(subject).to receive(:products_from_activations)
      subject.activated_products
    end
  end

  describe '#activations' do
    it 'memoizes activations by the first call' do
      allow(subject).to receive(:activations_from_server).and_return(:superdo)
      expect(subject.activations).to be subject.activations
    end

    it 'calls products_from_zypper from Status class' do
      expect(subject).to receive(:activations_from_server)
      subject.activations
    end
  end

  describe '#activated_base_product?' do
    it 'returns false if sytem does not have credentials' do
      allow(System).to receive(:credentials?).and_return(false)
      # We should not call activated_products if we don't have credentials
      expect(subject).not_to receive(:activated_products)
      expect(subject.activated_base_product?).to be false
    end

    it 'returns false if sytem has credentials but not activated' do
      allow(System).to receive(:credentials?).and_return(true)
      allow(Zypper).to receive(:base_product).and_return('base_product')
      expect(subject).to receive(:activated_products).and_return([])
      expect(subject.activated_base_product?).to be false
    end

    it 'returns true if sytem has credentials and activated' do
      allow(System).to receive(:credentials?).and_return(true)
      expect(Zypper).to receive(:base_product).and_return('base_product')
      expect(subject).to receive(:activated_products).and_return(['base_product'])
      expect(subject.activated_base_product?).to be true
    end
  end



  describe '#print_product_statuses' do
    context 'text format' do
      it 'reads template from erb file' do
        expect(File).to receive(:read).with(include('templates/product_statuses.text.erb')).and_return '111'
        allow(subject).to receive(:puts)
        subject.print_product_statuses
      end

      it 'builds proper erb entity' do
        allow(File).to receive(:read).and_return('blaherbfile')
        allow(described_class).to receive(:puts)
        mock_erb = double('mock_erb')
        allow(mock_erb).to receive(:result)
        expect(ERB).to receive(:new).with('blaherbfile', 0, '-<>').and_return mock_erb
        subject.print_product_statuses
      end

      it 'outputs the result of parsing erb with bindings' do
        allow(File).to receive(:read).and_return('blaherbfile')
        expect(subject).to receive(:puts).with('parsed erb output')
        mock_erb = double('mock_erb')
        allow(mock_erb).to receive(:result).and_return('parsed erb output')
        allow(ERB).to receive(:new).with('blaherbfile', 0, '-<>').and_return mock_erb
        subject.print_product_statuses
      end
    end

    context 'json format' do
      it 'outputs the system status in json format' do
        status = Zypper::ProductStatus.new(Zypper::Product.new({}), subject)
        allow(status).to receive(:registration_status) { 'test' }
        allow(status).to receive(:remote_product) { true }
        expect(status).to receive_message_chain(:remote_product, :free).and_return(false)
        activation = SUSE::Connect::Remote::Activation.new('service' => { 'product' => {} })
        allow(status).to receive(:related_activation).and_return(activation)

        expect(subject).to receive(:product_statuses).and_return [status]
        expect(subject).to receive(:puts)
        subject.print_product_statuses(:json)
      end
    end

    context 'unsupported format' do
      it 'errors out on unsupported format' do
        expect { subject.print_product_statuses(:xml) }.to raise_error(UnsupportedStatusFormat, "Unsupported output format 'xml'")
      end
    end
  end

  describe '#print_extensions_list' do
    it 'outputs the list of extensions available on the system' do
      allow(Zypper).to receive(:base_product).and_return Zypper::Product.new(:name => 'SLES', :version => '12', :arch => 'x86_64')
      allow(client_double).to receive(:show_product).with(Zypper.base_product).and_return(Remote::Product.new(dummy_product_data))
      expect { subject.print_extensions_list }.to output(/SUSE Linux Enterprise Software Development Kit 12 ppc64le/).to_stdout
      expect { subject.print_extensions_list }.to output(%r{sle-sdk/12/ppc64le}).to_stdout
      expect { subject.print_extensions_list }.to output(/SUSE Linux Enterprise Live Patching Module 12 ppc64le/).to_stdout
      expect { subject.print_extensions_list }.to output(%r{sle-live-patching/12/ppc64le}).to_stdout
      expect { subject.print_extensions_list }.to output(/SUSE Linux Enterprise Unreal Module 12 ppc64le/).to_stdout
      expect { subject.print_extensions_list }.to output(%r{sle-unreal/12/ppc64le}).to_stdout
      expect { subject.print_extensions_list }.not_to output(/Unavailable/).to_stdout
    end
  end

  describe '#available_system_extensions' do
    it 'returns a list of all available extensions on this system' do
      allow(Zypper).to receive(:base_product).and_return Zypper::Product.new(:name => 'SLES', :version => '12', :arch => 'x86_64')
      allow(client_double).to receive(:show_product).with(Zypper.base_product).and_return(Remote::Product.new(dummy_product_data))
      expect(subject.available_system_extensions).to match_array([
        {
          activation_code: 'sle-sdk/12/ppc64le',
          name: 'SUSE Linux Enterprise Software Development Kit 12 ppc64le',
          free: true,
          extensions: []
        },
        {
          activation_code: 'sle-live-patching/12/ppc64le',
          name: 'SUSE Linux Enterprise Live Patching Module 12 ppc64le',
          free: false,
          extensions: [{
            activation_code: 'sle-unreal/12/ppc64le',
            name: 'SUSE Linux Enterprise Unreal Module 12 ppc64le',
            free: true,
            extensions: []
          }]
        }])
    end
  end

  describe '#system_products' do
    let(:zypper_product) { Zypper::Product.new(:name => 'SLES', :version => '12', :arch => 'x86_64') }
    let(:remote_product) { Remote::Product.new(:identifier => 'SLES', :version => '12', :arch => 'x86_64', :release_type => 'HP-CNB') }
    let(:remote_product_dup) { Remote::Product.new(:identifier => 'SLES', :version => '12', :arch => 'x86_64') }

    it 'returns the installed and activated products from system' do
      expect_any_instance_of(Status).to receive(:installed_products).and_return([zypper_product])
      expect_any_instance_of(Status).to receive(:activated_products).and_return([remote_product, remote_product_dup])
      result = subject.system_products
      expect(result).to match_array([Product.transform(zypper_product), Product.transform(remote_product)])
    end
  end

  describe 'private' do
    describe '?product_statuses' do
      it 'wrapping each installed product into Zypper::ProductStatus' do
        allow(subject).to receive(:installed_products).and_return([:f, :a, :b])
        expect(Zypper::ProductStatus).to receive(:new).with(:f, subject)
        expect(Zypper::ProductStatus).to receive(:new).with(:a, subject)
        expect(Zypper::ProductStatus).to receive(:new).with(:b, subject)
        subject.send(:product_statuses)
      end
    end

    describe '?products_from_zypper' do
      it 'uses zypper output to collect info' do
        expect(Zypper).to receive_message_chain(:installed_products).and_return [1, 2, 3]
        expect(subject.send(:products_from_zypper)).to eq [1, 2, 3]
      end
    end

    describe '?products_from_activations' do
      it 'uses clients response to collect info' do
        fake_client = double('client')
        allow(Client).to receive(:new).and_return(fake_client)
        allow(SUSE::Connect::System).to receive(:credentials?).and_return true
        expect(fake_client).to receive_message_chain(:system_activations, :body, :map).and_return [1, 2, 3]
        expect(subject.send(:products_from_activations)).to eq [1, 2, 3]
      end
    end

    describe '?activations_from_server' do
      it 'mapping system_activations response to Remote::Activations' do
        allow(subject).to receive(:system_activations).and_return([1, 2, 3])
        expect(Remote::Activation).to receive(:new).with(1)
        expect(Remote::Activation).to receive(:new).with(2)
        expect(Remote::Activation).to receive(:new).with(3)
        subject.send(:activations_from_server)
      end
    end
  end

  def dummy_product_data
    JSON.parse(File.read('spec/fixtures/product_with_extensions.json'))
  end
end
