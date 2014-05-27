require 'spec_helper'

describe SUSE::Connect::YaST do

  subject { SUSE::Connect::YaST }

  let(:client) { double 'client' }
  before { Client.stub(:new).and_return(client) }

  describe '#announce_system' do

    let (:params) { { :distro_target => 'sles12-x86_64' } }
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

    it 'forwards distro_target param to announce' do
      client.should_receive( :announce_system ).with(params[:distro_target])
      subject.announce_system params
    end

  end

  describe '#activate_product' do

    let (:params) { { token: 'regcode', email: 'foo@bar.zer', product_ident: {:name => 'win95'} } }
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

    it 'forwards product_ident and email to Client#activate_product' do
      client.should_receive(:activate_product).with(params[:product_ident], params[:email])
      subject.activate_product params
    end

  end

  describe '#upgrade_product' do

    let (:params) { { product_ident: {:name => 'win95'} } }
    before { client.stub :upgrade_product }

    it 'calls upgrade_product on an instance of Client' do
      client.should_receive :upgrade_product
      subject.upgrade_product
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(params).and_return(client)
      subject.upgrade_product params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_return(client)
      subject.upgrade_product
    end

    it 'forwards product_ident to Client#upgrade_product' do
      client.should_receive(:upgrade_product).with(params[:product_ident])
      subject.upgrade_product params
    end

  end

  describe '#list_products' do

    let (:params) { { product_ident: {:name => 'win95'} } }
    before { client.stub :list_products }

    it 'calls list_products on an instance of Client' do
      client.should_receive :list_products
      subject.list_products
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(params).and_return(client)
      subject.list_products params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_return(client)
      subject.list_products
    end

    it 'uses product_ident as parameter for Client#list_products' do
      client.should_receive(:list_products).with(params[:product_ident])
      subject.list_products params
    end

  end

end
