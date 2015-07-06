require 'spec_helper'

describe SUSE::Connect::Zypper::ProductStatus do
  let(:status) { double('status') }

  subject { described_class.new(1, status) }

  describe 'constants' do
    it 'holds registration statuses strings in REGISTRATION_STATUS_MESSAGES' do
      expect(described_class::REGISTRATION_STATUS_MESSAGES).to eq ['Registered', 'Not Registered']
    end
  end

  describe '.initialize' do
    it 'assigns @installed_products to passed argument' do
      instance = described_class.new(:foo_bar_baz, status)
      expect(instance.installed_product).to eq :foo_bar_baz
    end
  end

  describe '#registration_status?' do
    context 'product is registered' do
      it 'will be `Registered`' do
        allow(subject).to receive(:registered?).and_return true
        expect(subject.registration_status).to eq 'Registered'
      end
    end

    context 'product is not registered' do
      it 'will be `Not Registered`' do
        allow(subject).to receive(:registered?).and_return false
        expect(subject.registration_status).to eq 'Not Registered'
      end
    end
  end

  describe '#registered?' do
    it '`double-bangs` nil result of remote_product' do
      allow(subject).to receive(:remote_product).and_return nil
      expect(subject.registered?).to eq false
    end

    it '`double-bangs` any not nil result of remote_product' do
      allow(subject).to receive(:remote_product).and_return double('test')
      expect(subject.registered?).to eq true
    end
  end

  describe '#related_activation' do
    it 'returns nil if there is no remote_product found' do
      allow(subject).to receive(:remote_product).and_return nil
      expect(subject.related_activation).to be nil
    end

    it 'finds related activation by comparing installing and remote product' do
      activation = double('activation')
      remote_product = Remote::Product.new(:identifier => :foo, :version => 42, :arch => :wax)
      activation.stub_chain(:service, :product).and_return remote_product
      allow(status).to receive(:activations).and_return [activation]
      allow(subject).to receive(:remote_product).and_return remote_product
      expect(subject.related_activation).to eq activation
    end
  end

  describe '#remote_product' do
    it 'search if there is a product in activations which is equal to one installed' do
      remote_product = Remote::Product.new(:identifier => :foo, :version => 42, :arch => :wax)
      allow(subject).to receive(:installed_product).and_return(Zypper::Product.new(:name => :foo, :version => 42, :arch => :wax))
      allow(status).to receive(:activated_products).and_return([remote_product])
      expect(subject.remote_product).to eq remote_product
    end
  end
end
