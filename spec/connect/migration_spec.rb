require 'spec_helper'

describe SUSE::Connect::Migration do
  describe '.system_products' do
    let(:zypper_product) { Zypper::Product.new(name: 'SLES', version: '12', arch: 'x86_64') }
    let(:remote_product) { Remote::Product.new(identifier: 'SLES', version: '12', arch: 'x86_64', release_type: 'HP-CNB') }

    it 'returns installed products and status activated products' do
      expect_any_instance_of(SUSE::Connect::Status).to receive(:system_products).and_return([Product.transform(zypper_product),
                                                                                             Product.transform(remote_product)])
      result = described_class.system_products
      expect(result).to match_array([Product.transform(zypper_product), Product.transform(remote_product)])
    end
  end

  # Forwards the repository which should be enabled with zypper
  # @param [String] repository name to enable
  def enable_repository(name)
    Zypper.enable_repository(name)
  end

  # Forwards the repository which should be disabled with zypper
  # @param [String] repository name to disable
  def disable_repository(name)
    Zypper.disable_repository(name)
  end

  # Returns the list of available repositories
  # @return [Array <OpenStruct>] the list of zypper repositories
  def repositories
    # INFO: use block instead of .map(&:to_openstruct) see https://bugs.ruby-lang.org/issues/9786
    Zypper.repositories.map{|r| r.to_openstruct }
  end

  describe '.enable_repository' do
    it 'enables zypper repository' do
      expect(SUSE::Connect::Zypper).to receive(:enable_repository).with('repository_name')
      described_class.enable_repository('repository_name')
    end
  end

  describe '.disable_repository' do
    it 'disables zypper repository' do
      expect(SUSE::Connect::Zypper).to receive(:disable_repository).with('repository_name')
      described_class.disable_repository('repository_name')
    end
  end

  describe '.repositories' do
    it 'calls underlying method of Zypper class' do
      expect(SUSE::Connect::Zypper).to receive(:repositories).and_return([])
      described_class.repositories
    end

    it 'returns an array of OpenStruct objects' do
      expect(SUSE::Connect::Zypper).to receive(:repositories).and_return([{name: 'foo'}, {name: 'bar'}])
      expect(described_class.repositories.any?{|r| r.is_a?(OpenStruct)}).to be true
    end
  end

  describe '.remove_service' do
    it 'forwards to zypper remove_service' do
      service_name = 'bla'
      expect(SUSE::Connect::Zypper).to receive(:remove_service).with(service_name)

      described_class.remove_service(service_name)
    end
  end

end
