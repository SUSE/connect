require 'spec_helper'

describe SUSE::Connect::Product do

  subject do
    extension = {
      'id' => 700,
      'name' => 'SLEEK',
      'long_name' => 'SUSE LINUX ENTERPRISE EXTENSION KDE',
      'description' => 'SLEEK puts the modern yet familiar GUI back into SLE that you love',
      'zypper_name' => 'SLEEK-12',
      'zypper_version' => '12',
      'arch' => 'x86_64',
      'free' => true,
      'eula_url' => 'https://nu.novell.com/SUSE:/Products:/SLE-12/images/' \
        'repo/SLE-12-module-sleek-POOL-x86_64-Media.license/'
      }
    SUSE::Connect::Product.new(extension)
  end

  describe '.new' do

    describe 'readers' do

      context :api_product do

        it 'has attribute short_name' do
          expect(subject.short_name).not_to be_nil
        end

        it 'has attribute long_name' do
          expect(subject.long_name).not_to be_nil
        end

        it 'has attribute description' do
          expect(subject.description).not_to be_nil
        end

        it 'has attribute product_ident' do
          expect(subject.product_ident).not_to be_nil
        end

        it 'has attribute version' do
          expect(subject.version).not_to be_nil
        end

        it 'has attribute arch' do
          expect(subject.arch).not_to be_nil
        end

        it 'has attribute eula_url' do
          expect(subject.eula_url).not_to be_nil
        end

        it 'has attribute id' do
          expect(subject.id).to eq 700
        end

      end

    end

  end

  describe '#==' do

    context :reg_server_product do

      it 'equal with other product if product_ident, version and arch are equal' do
        zypper_product = RegServerProduct.new(:zypper_name => 'SLEEK-12', :zypper_version => '12', :release_type => '', :arch => 'x86_64')
        expect(subject == zypper_product).to be true
      end

      it 'is not equal with other product if product_ident or version or arch are different' do
        zypper_product = RegServerProduct.new(:zypper_name => 'SLEEK-12', :zypper_version => '13', :release_type => '', :arch => 'x86_64')
        expect(subject == zypper_product).to be false
      end

      it 'is not equal with other product if product_ident or version or arch are different' do
        zypper_product = RegServerProduct.new(:zypper_name => 'PLEEK-12', :zypper_version => '12', :release_type => '', :arch => 'x86_64')
        expect(subject == zypper_product).to be false
      end

      it 'is not equal with other product if product_ident or version or arch are different' do
        zypper_product = RegServerProduct.new(:zypper_name => 'SLEEK-12', :zypper_version => '12', :release_type => '', :arch => 'ia64')
        expect(subject == zypper_product).to be false
      end

      it 'is not equal with other product if product_ident or version or arch are nil' do
        zypper_product = RegServerProduct.new(:zypper_name => nil, :zypper_version => nil, :release_type => '', :arch => 'ia64')
        expect(subject == zypper_product).to be false
      end

      it 'returns false if other is not subjects class' do
        [:foo, 'bar', 12, 12.5].each do |other|
          expect(subject == other).to be false
        end

      end

    end

  end

end
