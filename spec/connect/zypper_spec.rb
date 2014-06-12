require 'spec_helper'

describe SUSE::Connect::Zypper do

  before(:each) do
    Object.stub(:system => true)
  end

  after(:each) do
    SUSE::Connect::System.filesystem_root = nil
  end

  subject { SUSE::Connect::Zypper }

  describe '.installed_products' do

    context :sle11 do
      context :sp3 do

        let(:xml) { File.read('spec/fixtures/product_valid_sle11sp3.xml') }

        before do
          params = '--no-refresh --quiet --xmlout --non-interactive products -i'
          subject.should_receive(:call_zypper).with(:with_output, params).and_return(xml)
        end

        it 'returns valid list of products based on proper XML' do
          subject.installed_products.first.identifier.should eq 'SUSE_SLES'
        end

        it 'returns valid version' do
          subject.installed_products.first.version.should eq '11.3'
        end

        it 'returns valid arch' do
          subject.installed_products.first.arch.should eq 'x86_64'
        end

        it 'returns proper base product' do
          subject.base_product.identifier.should eq 'SUSE_SLES'
        end

      end
    end

    context :sle12 do
      context :sp0 do

        let(:xml) { File.read('spec/fixtures/product_valid_sle12sp0.xml') }

        before do
          params = '--no-refresh --quiet --xmlout --non-interactive products -i'
          subject.should_receive(:call_zypper).with(:with_output, params).and_return(xml)
        end

        it 'returns valid name' do
          subject.installed_products.first.identifier.should eq 'SLES'
        end

        it 'returns valid version' do
          subject.installed_products.first.version.should eq '12'
        end

        it 'returns valid arch' do
          subject.installed_products.first.arch.should eq 'x86_64'
        end

        it 'returns proper base product' do
          subject.base_product.identifier.should eq 'SLES'
        end

      end
    end

  end

  describe '.add_service' do

    it 'calls zypper with proper arguments' do
      parameters = "zypper --quiet --non-interactive addservice -t ris http://example.com 'branding'"
      expect(subject).to receive(:system).with(parameters).and_return(true)
      subject.add_service('http://example.com', 'branding')
    end

    it 'escapes shell parameters' do
      parameters = "zypper --quiet --non-interactive addservice -t ris http://example.com\\;id 'branding'"
      expect(subject).to receive(:system).with(parameters).and_return(true)
      subject.add_service('http://example.com;id', 'branding')
    end

    it 'calls zypper with proper arguments --root case' do
      parameters = "zypper --root '/path/to/root' --quiet --non-interactive addservice " \
                   "-t ris http://example.com 'branding'"
      expect(subject).to receive(:system).with(parameters).and_return(true)
      SUSE::Connect::System.filesystem_root = '/path/to/root'
      subject.add_service('http://example.com', 'branding')
    end

  end

  describe '.remove_service' do

    it 'calls zypper with proper arguments' do
      parameters = "zypper --quiet --non-interactive removeservice 'branding'"
      expect(subject).to receive(:system).with(parameters).and_return(true)
      subject.remove_service('branding')
    end

    it 'calls zypper with proper arguments --root case' do
      parameters = "zypper --root '/path/to/root' --quiet --non-interactive removeservice 'branding'"
      expect(subject).to receive(:system).with(parameters).and_return(true)
      SUSE::Connect::System.filesystem_root = '/path/to/root'
      subject.remove_service('branding')
    end

  end

  describe '.refresh' do

    it 'calls zypper with proper arguments' do
      expect(subject).to receive(:system).with('zypper refresh').and_return(true)
      subject.refresh
    end

    it 'calls zypper with proper arguments --root case' do
      SUSE::Connect::System.filesystem_root = '/path/to/root'
      subject.should_receive(:system).with("zypper --root '/path/to/root' refresh").and_return(true)
      subject.refresh
    end

  end

  describe '.base_product' do

    let :parsed_products do
      [
        SUSE::Connect::Zypper::Product.new(:isbase => '1', :name => 'SLES', :productline => 'SLE_productline1', :registerrelease => ''),
        SUSE::Connect::Zypper::Product.new(:isbase => '2', :name => 'Cloud', :productline => 'SLE_productline2', :registerrelease => '')
      ]
    end

    before do
      subject.stub(:installed_products => parsed_products)
      Credentials.any_instance.stub(:write)
    end

    it 'should return first product from installed product which is base' do
      subject.base_product.should eq(parsed_products.first)
    end

    it 'raises CannotDetectBaseProduct if cant get base system from list of installed products' do
      product = double('Product', :isbase => false)
      allow(Zypper).to receive(:installed_products).and_return([product])
      expect { Zypper.base_product }.to raise_error(CannotDetectBaseProduct)
    end

  end

  describe '.write_base_credentials' do

    mock_dry_file

    before do
      Credentials.any_instance.stub(:write)
    end

    it 'should call write_base_credentials_file' do
      Credentials.should_receive(:new).with('dummy', 'tummy', Credentials::GLOBAL_CREDENTIALS_FILE).and_call_original
      subject.write_base_credentials('dummy', 'tummy')
    end

  end

  describe '.write_service_credentials' do

    mock_dry_file

    before do
      Credentials.any_instance.stub(:write)
    end

    it 'extracts username and password from system credentials' do
      System.should_receive(:credentials)
      subject.write_service_credentials('turbo')
    end

    it 'creates a file with source name' do
      Credentials.should_receive(:new).with('dummy', 'tummy', 'turbo').and_call_original
      subject.write_service_credentials('turbo')
    end

  end

  describe '.distro_target' do
    it 'return zypper targetos output' do
      subject.should_receive(:'`').with('zypper targetos').and_return('openSUSE-13.1-x86_64')
      Zypper.distro_target.should eq 'openSUSE-13.1-x86_64'
    end

    it 'return zypper targetos output --root case' do
      subject.should_receive(:'`').with("zypper --root '/path/to/root' targetos").and_return('openSUSE-13.1-x86_64')
      SUSE::Connect::System.filesystem_root = '/path/to/root'
      Zypper.distro_target.should eq 'openSUSE-13.1-x86_64'
    end
  end

end
