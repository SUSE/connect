require 'spec_helper'
require 'suse/connect/core_ext/hash_refinement'

describe SUSE::Connect::CoreExt::HashRefinement do
  describe '.to_openstruct' do
    using described_class

    let(:hash) { { a: 1, b: 2 } }

    it 'converts hash to openstruct' do
      result = hash.to_openstruct
      expect(result).to be_a OpenStruct
      expect(result).to respond_to :a
      expect(result).to respond_to :b
    end
  end
end
