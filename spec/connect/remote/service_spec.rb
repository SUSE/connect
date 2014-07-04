require 'spec_helper'

describe SUSE::Connect::Remote::Service do

  subject { described_class }

  describe '.new' do

    let(:service) { subject.new(JSON.parse(File.read('spec/fixtures/activate_response.json'))) }

    it 'contains name' do
      expect(service.name).to_not be_empty
    end

    it 'contains id' do
      expect(service.id).to eq 42
    end

    it 'contains url' do
      expect(service.url).to_not be_empty
    end

    it 'contains product' do
      expect(service.product).to_not be_nil
    end

  end

end
