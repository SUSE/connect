require 'spec_helper'
require 'ostruct'

describe SUSE::Connect::ApiError do
  let(:with_http_message) { OpenStruct.new(http_message: 'foo', code: 1337) }

  let(:with_error) do
    OpenStruct.new(
      http_message: 'foo',
      body: { 'error' => 'bar' }
    )
  end

  let(:with_localized_error) do
    OpenStruct.new(
      http_message: 'foo',
      body: { 'error' => 'bar',
              'localized_error' => 'baz' }
    )
  end

  describe '#code' do
    it 'returns the http status code' do
      expect(described_class.new(with_http_message).code).to eq(1337)
    end
  end

  describe '#message' do
    it 'returns the http message' do
      expect(described_class.new(with_http_message).message).to eq('foo')
    end

    it 'returns the not localized error' do
      expect(described_class.new(with_error).message).to eq('bar')
    end

    it 'returns the localized error' do
      expect(described_class.new(with_localized_error).message).to eq('baz')
    end
  end
end
