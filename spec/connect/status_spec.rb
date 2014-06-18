require 'spec_helper'

describe SUSE::Connect::Status do

  subject { described_class }

  describe '.initialize' do

    it 'sets client accessor' do
      allow_any_instance_of(Status).to receive(:activated_products).and_return(:baz)
      status = subject.new(:foo)
      expect(status.send(:client)).to eq :foo
    end

    it 'returns self' do
      allow_any_instance_of(Status).to receive(:activated_products).and_return(:baz)
      expect(subject.new(:foo)).to be_kind_of Status
    end

  end

  describe '#installed_products' do

    it 'memorizes content by first call' do
      allow_any_instance_of(Status).to receive(:products_from_zypper).and_return([1, 2, :foo])
      status = subject.new(:foo)
      first_call_result = status.installed_products
      expect(first_call_result).to equal status.products_from_zypper
    end

  end

  describe '#activated_products' do

    it 'memorizes content by first call' do
      allow_any_instance_of(Status).to receive(:products_from_services).and_return([1, 2, :foo])
      status = subject.new(:foo)
      first_call_result = status.activated_products
      expect(first_call_result).to equal status.activated_products
    end

  end

  describe '#known_subscriptions' do

    it 'memorizes content by first call' do
      allow_any_instance_of(Status).to receive(:subscriptions_from_server).and_return([1, 2, :foo])
      status = subject.new(:foo)
      first_call_result = status.known_subscriptions
      expect(first_call_result).to equal status.known_subscriptions
    end

  end

  describe '#subscriptions_from_server' do

    it 'uses clients response to collect info' do
      fake_client = double('client')
      fake_client.stub_chain(:system_subscriptions, :body, :map).and_return [1, 2, 3]
      expect(subject.new(fake_client).send(:subscriptions_from_server)).to eq [1, 2, 3]
    end

  end

  describe '#products_from_services' do

    it 'uses clients response to collect info' do
      fake_client = double('client')
      fake_client.stub_chain(:system_services, :body, :map).and_return [1, 2, 3]
      expect(subject.new(fake_client).send(:products_from_services)).to eq [1, 2, 3]
    end

  end

  describe '#products_from_zypper' do

    it 'uses zypper output to collect info' do
      Zypper.stub_chain(:installed_products, :map).and_return [1, 2, 3]
      expect(subject.new(:foo).send(:products_from_zypper)).to eq [1, 2, 3]
    end

  end

  describe '#print' do

    it 'prints the system status' do
      PP.stub(:pp).and_return '123'
      expect(subject.new(:foo).send(:print)).to eq '123'
    end

  end

end
