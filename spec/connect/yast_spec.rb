require 'spec_helper'

describe SUSE::Connect::YaST do

  subject { SUSE::Connect::YaST }

  describe '#announce_system' do

    let(:params) { { :distro_target => 'sles12-x86_64' } }
    before { Client.any_instance.stub :announce_system }

    it 'calls announce_system on an instance of Client' do
      Client.any_instance.should_receive(:announce_system)
      subject.announce_system
    end

    it 'passes distro_target parameter to announce' do
      Client.any_instance.should_receive(:announce_system).with(params[:distro_target])
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

    let(:params) { { token: 'regcode', email: 'foo@bar.zer', product_ident: { :name => 'win95' } } }
    before { Client.any_instance.stub :activate_product }

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

  describe '#upgrade_product' do

    let(:params) { { product_ident: { :name => 'win95' } } }
    before { Client.any_instance.stub :upgrade_product }

    it 'calls upgrade_product on an instance of Client' do
      Client.any_instance.should_receive :upgrade_product
      subject.upgrade_product
    end

    it 'forwards all params to an instance of Client' do
      Client.should_receive(:new).with(params).and_call_original
      subject.upgrade_product params
    end

    it 'falls back to use an empty Hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_call_original
      subject.upgrade_product
    end

    it 'forwards product_ident to Client#upgrade_product' do
      Client.any_instance.should_receive(:upgrade_product).with(params[:product_ident])
      subject.upgrade_product params
    end

  end

  describe '#list_products' do

    let(:params) { { product_ident: { :name => 'win95' } } }
    before { Client.any_instance.stub :list_products }

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
