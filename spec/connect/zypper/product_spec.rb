require 'spec_helper'

describe SUSE::Connect::Zypper::Product do

  subject { SUSE::Connect::Zypper::Product }

  describe '.initialize' do

    it 'stores passed argument in product_hash instance variable' do
      passed = { :name => 'foo' }
      expect(subject.new(passed).instance_variable_get('@product_hash')).to eq passed
    end

    it 'set identifier from name key' do
      expect(subject.new(:name => 'foo').identifier).to eq 'foo'
    end

    it 'set version from version key' do
      expect(subject.new(:version => 42).version).to eq 42
    end

    it 'set arch from arch key' do
      expect(subject.new(:arch => 'x86_64').arch).to eq 'x86_64'
    end

    describe :isbase do

      context :isbase_is_1 do

        it 'set isbase to true if isbase key is equal 1' do
          expect(subject.new(:isbase => '1').isbase).to be true
        end

      end

      context :isbase_is_yes do

        it 'set isbase to true if isbase key is equal yes' do
          expect(subject.new(:isbase => 'yes').isbase).to be true
        end

      end

      context :isbase_is_true do

        it 'set isbase to true if isbase key is equal true' do
          expect(subject.new(:isbase => 'true').isbase).to be true
        end

      end

      context :isbase_is_different do

        it 'set isbase to true if isbase key is equal true' do
          %w{ foo aga sc 42 false}.each do |variant|
            expect(subject.new(:isbase => variant).isbase).to be false
          end

        end

      end

    end

    describe 'release type' do

      context :flavor_present do

        it 'set release_type based on precendce logic of several keys of passed product' do
          expect(subject.new(:flavor => 'floppy').release_type).to eq 'floppy'
        end

      end

      context :registerrelease_present do

        it 'set release_type based on registerrelease_present' do
          expect(subject.new(:registerrelease => 'OEMBBC').release_type).to eq 'OEMBBC'
        end

        it 'set release_type back to flavor if registerrelease is empty' do
          product_hash = { :flavor => 'floppy', :registerrelease => '' }
          expect(subject.new(product_hash).release_type).to eq 'floppy'
        end

      end

      context :oemfile_exists do

        it 'set release_type based on OEM file content' do
          file = File.join(SUSE::Connect::Zypper::OEM_PATH, 'NagaokaRobotics')
          allow(File).to receive(:exist?).with(file).and_return true
          allow(File).to receive(:readlines).with(file).and_return ["kabooom\n"]
          expect(subject.new(:productline => 'NagaokaRobotics').release_type).to eq 'kabooom'
        end

      end

      context :oemfile_does_not_exists do

        it 'fallback to registerrelease if productline passed, but does not exist' do
          product_hash = { :registerrelease => 'sic', :productline => 'NagaokaRobotics' }
          file = File.join(SUSE::Connect::Zypper::OEM_PATH, 'NagaokaRobotics')
          allow(File).to receive(:exist?).with(file).and_return false
          expect(subject.new(product_hash).release_type).to eq 'sic'
        end

      end

    end

  end

end
