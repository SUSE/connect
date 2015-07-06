require 'spec_helper'

describe SUSE::Connect::Remote::Activation do
  subject { described_class }

  describe '.new' do
    let(:activation) { described_class.new(JSON.parse(File.read('spec/fixtures/activations_response.json')).last) }

    it 'contains id' do
      expect(activation.id).to eq 124_232
    end

    it 'contains regcode' do
      expect(activation.regcode).to eq 'Babboom'
    end

    it 'contains type' do
      expect(activation.type).to eq 'evaluation'
    end

    it 'contains status' do
      expect(activation.status).to eq 'ACTIVE'
    end

    it 'contains starts_at' do
      expect(activation.starts_at).to eq '2012-07-21T00:00:00.000Z'
    end

    it 'contains expires_at' do
      expect(activation.expires_at).to eq '2015-12-31T00:00:00.000Z'
    end

    it 'contains system_id' do
      expect(activation.system_id).to eq 34_242
    end

    it 'contains service' do
      expect(activation.service).to be_kind_of Remote::Service
    end

    it 'contains product withing service' do
      expect(activation.service.product).to be_kind_of Remote::Product
    end
  end
end
