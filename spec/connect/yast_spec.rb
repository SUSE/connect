require 'spec_helper'

describe SUSE::Connect::YaST do

  subject { SUSE::Connect::YaST }

  let(:params) { { token: 'regcode', email: 'foo@bar.zer' } }
  let(:client) { double 'client' }

  before { Client.stub(:new).and_return(client) }

  describe '#announce_system' do

    before { client.stub :announce_system }

    it 'calls announce_system on an instance of Client' do
      client.should_receive :announce_system
      subject.announce_system
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(params).and_return(client)
      subject.announce_system params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_return(client)
      subject.announce_system
    end

  end

  describe '#activate_product' do

    before { client.stub :activate_product }

    it 'calls activate_product on an instance of Client' do
      client.should_receive :activate_product
      subject.activate_product
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(params).and_return(client)
      subject.activate_product params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_return(client)
      subject.activate_product
    end

    it 'uses product_ident as parameter for Client#activate_product' do
      params[:product_ident] = 'SLE95'
      pp params
      client.should_receive(:activate_product).with('SLE95')
      subject.activate_product params
    end

  end

  describe '#list_products' do

  end

end
