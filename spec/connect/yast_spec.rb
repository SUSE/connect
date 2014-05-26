require 'spec_helper'

describe SUSE::Connect::YaST do

  subject { SUSE::Connect::YaST }

  let :params do
    { token: 'regcode', email: 'foo@bar.zer', product_ident: 'SLE95', :distro_target => 'sles12'}
  end

  describe '#announce_system' do

    it 'calls announce_system on an instance of Client' do
      Client.any_instance.should_receive(:announce_system)
      subject.announce_system
    end

    it 'passes distro_target parameter to announce' do
      Client.any_instance.should_receive(:announce_system).with('sles12')
      subject.announce_system params
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(params).and_call_original
      Client.any_instance.should_receive(:announce_system)
      subject.announce_system params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_call_original
      Client.any_instance.should_receive(:announce_system)
      subject.announce_system
    end

  end

  describe '#activate_product' do

    it 'calls activate_product on an instance of Client' do
      Client.any_instance.should_receive(:activate_product)
      subject.activate_product
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(params).and_call_original
      Client.any_instance.should_receive(:activate_product)
      subject.activate_product params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_call_original
      Client.any_instance.should_receive(:activate_product)
      subject.activate_product
    end

    it 'uses product_ident and email as parameter for Client#activate_product' do
      Client.should_receive(:new).with(params).and_call_original
      Client.any_instance.should_receive(:activate_product).with(params[:product_ident], params[:email])
      subject.activate_product params
    end

  end

  describe '#list_products' do

    it 'calls list_products on an instance of Client' do
      Client.any_instance.should_receive(:list_products)
      subject.list_products
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(params).and_call_original
      Client.any_instance.should_receive(:list_products)
      subject.list_products params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_call_original
      Client.any_instance.should_receive(:list_products)
      subject.list_products
    end

    it 'uses product_ident as parameter for Client#list_products' do
      Client.should_receive(:new).with(params).and_call_original
      Client.any_instance.should_receive(:list_products).with(params[:product_ident])
      subject.list_products params
    end

  end

end
