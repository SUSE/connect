require 'spec_helper'

describe SUSE::Connect::Product do

  describe '.transform' do
    it 'returns Product Class from Zypper products' do
      zypperprod = Zypper::Product.new(:name => 'SLES', :version => '12', :arch => 'x86_64')
      connectprod = described_class.transform(zypperprod)
      expect(connectprod).to be_kind_of(described_class)
      expect(connectprod.identifier).to eq(zypperprod.identifier)
      expect(connectprod.version).to eq(zypperprod.version)
      expect(connectprod.arch).to eq(zypperprod.arch)
      expect(connectprod.release_type).to eq(zypperprod.release_type)
    end

    it 'returns Product Class from Remote products' do
      remoteprod = Remote::Product.new(:identifier => 'SLES', :version => '12', :arch => 'x86_64', :release_type => 'HP-CNB')
      connectprod = described_class.transform(remoteprod)
      expect(connectprod).to be_kind_of(described_class)
      expect(connectprod.identifier).to eq(remoteprod.identifier)
      expect(connectprod.version).to eq(remoteprod.version)
      expect(connectprod.arch).to eq(remoteprod.arch)
      expect(connectprod.release_type).to eq(remoteprod.release_type)
    end

  end

end
