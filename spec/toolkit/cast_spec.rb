require 'spec_helper'

# Into this class instance we include subject module
class DummyReceiver < OpenStruct
  include SUSE::Toolkit::Cast
end

describe SUSE::Toolkit::Cast do
  subject { DummyReceiver.new(a: 1, b: 2, c: [DummyReceiver.new(x: 7, y: 8)]) }

  describe '.to_openstruct' do
    it 'casts an object to openstruct' do
      expect(subject.to_openstruct).to be_a OpenStruct
    end

    it 'performs a deep cast on the object with a class instances in array values' do
      expect(subject.to_openstruct.c.first).to be_a OpenStruct
    end
  end

  describe '.attributes' do
    it 'returns the attributes as a hash' do
      expect(subject.attributes).to be_a Hash
    end

    it 'converts the nested attribute values to hash' do
      expect(subject.attributes[:c].first).to be_a Hash
    end
  end
end
