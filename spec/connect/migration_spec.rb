require 'spec_helper'

describe SUSE::Connect::Migration do
  describe '#system_products' do
    let(:zypper_product) { Zypper::Product.new(:name => 'SLES', :version => '12', :arch => 'x86_64') }
    let(:remote_product) { Remote::Product.new(:identifier => 'SLES', :version => '12', :arch => 'x86_64', :release_type => 'HP-CNB') }

    it 'returns installed products and status activated products' do
      expect_any_instance_of(SUSE::Connect::Status).to receive(:system_products).and_return([Product.transform(zypper_product),
                                                                                             Product.transform(remote_product)])
      result = described_class.system_products
      expect(result).to match_array([Product.transform(zypper_product), Product.transform(remote_product)])
    end
  end

  describe '#add_service' do
    it 'forwards to zypper add_service' do
      service_url = 'http://bla.bla'
      service_name = 'bla'
      expect(SUSE::Connect::Zypper).to receive(:add_service).with(service_url, service_name)

      described_class.add_service(service_url, service_name)
    end
  end

  describe '#remove_service' do
    it 'forwards to zypper remove_service' do
      service_name = 'bla'
      expect(SUSE::Connect::Zypper).to receive(:remove_service).with(service_name)

      described_class.remove_service(service_name)
    end
  end

end
