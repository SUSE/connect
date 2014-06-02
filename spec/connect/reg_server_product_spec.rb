require 'spec_helper'

describe SUSE::Connect::RegServerProduct do

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
    described_class.new(extension)
  end

  it_behaves_like 'server driven model'

  describe '#==' do

    context :zypper_product do

      it 'equal with other product if product_ident, version and arch are equal' do
        zypper_product = Product.new('zypper_name' => 'SLEEK-12', 'zypper_version' => '12', 'arch' => 'x86_64')
        expect(subject == zypper_product).to be true
      end

      it 'is not equal with other product if product_ident or version or arch are different' do
        zypper_product = Product.new('zypper_name' => 'SLEEK-12', 'zypper_version' => '13', 'arch' => 'x86_64')
        expect(subject == zypper_product).to be false
      end

      it 'is not equal with other product if product_ident or version or arch are different' do
        zypper_product = Product.new('zypper_name' => 'PLEEK-12', 'zypper_version' => '12', 'arch' => 'x86_64')
        expect(subject == zypper_product).to be false
      end

      it 'is not equal with other product if product_ident or version or arch are different' do
        zypper_product = Product.new('zypper_name' => 'SLEEK-12', 'zypper_version' => '12', 'arch' => 'ia64')
        expect(subject == zypper_product).to be false
      end

      it 'is not equal with other product if product_ident or version or arch are nil' do
        zypper_product = Product.new('zypper_name' => nil, 'zypper_version' => nil, 'arch' => 'x86_64')
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
