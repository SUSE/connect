require 'spec_helper'
require 'ostruct'

describe SUSE::Connect::PackageSearch do
  subject { described_class }

  let(:config) do
    SUSE::Connect::Config.new.merge!({
      url: 'https://some.example.to.test.org',
      language: 'Piet',
      insecure: false,
      debug: false,
      token: 'a-tocken'
    })
  end

  let(:product) { SUSE::Connect::Zypper::Product.new(identifier: 'SLES', version: '15', arch: 'x86_64') }

  let(:result) { OpenStruct.new body: { data: [{ name: 'foo' }, { name: 'bar' }] }, success: true }

  describe '.search' do
    before do
      allow(SUSE::Connect::Config).to receive(:new).and_return(config)
    end

    it 'creates a config instance and a Api instance to make the request' do
      expect(SUSE::Connect::Config).to receive(:new).and_return(config)
      expect(SUSE::Connect::Api).to receive(:new).with(config).and_call_original
      expect_any_instance_of(SUSE::Connect::Api).to receive(:package_search).with(product, 'vim').and_return(result)

      subject.search('vim', product: product)
    end

    it 'overwrites configuration settings supplied as argument' do
      overwrites = { language: 'Bonk', debug: true }

      expect(config).to receive(:merge!).with(overwrites).and_call_original
      expect_any_instance_of(SUSE::Connect::Api).to receive(:package_search).and_return(result)

      subject.search('vim', product: product, config_params: overwrites)
    end

    it 'gets the base system from zypper if no product was supplied' do
      expect(Zypper).to receive(:base_product).and_return(product)
      expect_any_instance_of(SUSE::Connect::Api).to receive(:package_search).with(product, 'vim').and_return(result)
      subject.search('vim')
    end

    it 'returns the result of the request' do
      expect_any_instance_of(SUSE::Connect::Api).to receive(:package_search).with(product, 'vim').and_return(result)
      expect(subject.search('vim', product: product)).to eq result.body['data']
    end
  end
end
