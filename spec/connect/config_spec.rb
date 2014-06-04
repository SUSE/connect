require 'spec_helper'
require 'rubygems'

describe SUSE::Connect::Config do
  let(:config_file) { File.expand_path File.join(File.dirname(__FILE__), '../fixtures/SUSEConnect') }

  context 'class methods' do
    subject { SUSE::Connect::Config }

    after do
      subject.serializable_attributes :url, :insecure
    end

    it '.serializable_attributes' do
      subject.serializable_attributes :baz, :buz

      expect(subject.serializable).to include :baz, :buz
    end
  end

  context 'instance methods' do
    subject { SUSE::Connect::Config }
    let(:config) { subject.new(config_file) }

    context '#initializer' do
      it 'allows to read a config file from different location' do
        config = subject.new('/tmp/SUSEConnect')
        expect(config.instance_variable_get :@file).to eq '/tmp/SUSEConnect'
      end

      it 'initializes SUSE::Connect::Config object with properties from config file' do
        expect(config.regcode).to eq 'regcode'
        expect(config.url).to eq 'https://scc.suse.com'
        expect(config.language).to eq 'EN'
      end

      it 'is empty if file does not exist' do
        config = subject.new('/non-existing-file')
        expect(config.url).to be_nil
      end
    end

    context '#write' do
      it 'writes configuration settings to YAML file' do
        File.should_receive(:write).with(config_file, config.to_yaml).and_return(0)
        config.write
      end
    end

    context "#to_yaml" do
      it 'converts object attributes to yaml' do
        expect(YAML.load(config.to_yaml)).to_not be_empty
      end
    end
  end
end
