require 'spec_helper'

describe SUSE::Connect::Remote::Product do
  subject do
    product = {
      'id' => 700,
      'name' => 'SLEEK',
      'long_name' => 'SUSE LINUX ENTERPRISE EXTENSION KDE',
      'description' => 'SLEEK puts the modern yet familiar GUI back into SLE that you love',
      'identifier' => 'SLEEK-12',
      'version' => '12',
      'arch' => 'x86_64',
      'free' => true,
      'eula_url' => 'https://nu.novell.com/SUSE:/Products:/SLE-12/images/' \
      'repo/SLE-12-module-sleek-POOL-x86_64-Media.license/',
      'extensions' => [{ 'identifier' => 'SLEEK-12-EXT', 'version' => '12', 'arch' => 'x86_64' }],
      'product_type' => 'extension',
      'release_type' => 'HP-CNB'
    }
    described_class.new(product)
  end

  describe '#extensions' do
    it 'build as much nested extensions as returned by server' do
      subject = described_class.new('extensions' =>
        [
          {
            'foo' => 'bar',
            'extensions' => [
              { 'bar' => 'baz', 'extensions' => [] }
            ]
          }
        ])
      expect(subject.extensions.size).to eq 1
      expect(subject.extensions.first.extensions.size).to eq 1
      expect(subject.extensions.first.extensions.first.extensions).to eq []
    end

    it 'has extensions' do
      expect(subject.extensions.size).to eq 1
      expect(subject.extensions.first.identifier).to eq 'SLEEK-12-EXT'
    end
  end

  describe '#distro_target' do
    it 'generate distro target' do
      expect(subject.distro_target).to eq 'sle-12-x86_64'
    end
  end

  it_behaves_like 'server driven model'

  describe '#==' do
    context 'zypper product' do
      it 'is equal with zypper product if identifier, version and arch are equal' do
        zypper_product = Zypper::Product.new(name: 'SLEEK-12', version: '12', arch: 'x86_64')
        expect(subject == zypper_product).to be true
      end

      it 'is not equal with zypper product if version differs' do
        zypper_product = Zypper::Product.new(name: 'SLEEK-12', version: '13', arch: 'x86_64')
        expect(subject == zypper_product).to be false
      end

      it 'is not equal with zypper product if name differs' do
        zypper_product = Zypper::Product.new(name: 'PLEEK-12', version: '13', arch: 'x86_64')
        expect(subject == zypper_product).to be false
      end

      it 'is not equal with zypper product if arch differs' do
        zypper_product = Zypper::Product.new(name: 'SLEEK-12', version: '13', arch: 'ia64')
        expect(subject == zypper_product).to be false
      end

      it 'is not equal with zypper product if name, version, arch are all nil' do
        zypper_product = Zypper::Product.new(name: nil, version: nil, arch: nil)
        expect(subject == zypper_product).to be false
      end

      it 'returns false if other is not subjects class' do
        [:foo, 'bar', 12, 12.5].each do |other|
          expect(subject == other).to be false
        end
      end
    end
  end

  describe '#to_params' do
    it "returns a hash with the product's identifier, version, arch and release_type" do
      expect(subject.to_params).to eq(identifier: 'SLEEK-12', version: '12', arch: 'x86_64', release_type: 'HP-CNB')
    end
  end

  describe '#to_openstruct' do
    it 'responds to to_openstruct method' do
      expect(subject).to respond_to(:to_openstruct)
    end
  end
end
