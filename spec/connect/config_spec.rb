require 'spec_helper'
require 'rubygems'
require 'debugger'

describe SUSE::Connect::Config do
  let(:config_file) { File.expand_path File.join(File.dirname(__FILE__), '../fixtures/SUSEConnect.yml') }

  context 'class methods' do
    subject { SUSE::Connect::Config }

    after do
      subject.attribute_accessors :url, :regcode, :language
    end

    it '.attribute_accessors' do
      subject.attribute_accessors :foo, :bar

      expect(subject.attributes).to include :foo, :bar
      expect(subject.respond_to?('attributes')).to be_true
    end
  end

  context 'instance methods' do
    subject { SUSE::Connect::Config }
    let(:config) { subject.new(config_file) }

    context '#initializer' do
      it 'allows to read a config file from defferent location' do
        config = subject.new('/tmp/SUSEConnect.yml')
        expect(config.instance_variable_get :@file).to eq '/tmp/SUSEConnect.yml'
      end

      it 'initializes SUSE::Connect::Config object with properties from config file' do
        expect(config.regcode).to eq 'regcode'
        expect(config.url).to eq 'https://scc.suse.com'
        expect(config.language).to eq 'EN'
      end
    end

    context '#read' do
      it 'reads configuration settings from YAML file if present' do
        File.should_receive(:exist?).at_least(:once).with(config_file).and_return(true)
        YAML.should_receive(:load_file).with(config_file).and_return({'regcode' => 'test', 'url' => 'localhost', 'language' => 'DE'})

        settings = config.read
        expect(settings).to be_kind_of(Hash)
        expect(settings.values).to include('test')
        expect(settings.values).to include('localhost')
        expect(settings.values).to include('DE')
      end

      it 'returns empty hash if file not found' do
        File.should_receive(:exist?).at_least(:once).with(config_file).and_return(false)

        settings = config.read
        expect(settings).to be_kind_of(Hash)
        expect(settings.empty?).to be_true
      end
    end

    it 'reads configuration settings from YAML file' do
      File.should_receive(:exist?).at_least(:once).with(config_file).and_return(true)
      YAML.should_receive(:load_file).with(config_file).and_return({'regcode' => 'test', 'url' => 'localhost', 'language' => 'DE'})

      settings = config.read
      expect(settings).to be_kind_of(Hash)
      expect(settings.values).to include('test')
      expect(settings.values).to include('localhost')
      expect(settings.values).to include('DE')
    end

    it 'writes configuration settings to YAML file' do
      File.should_receive(:write).with(config_file, config.to_yml).and_return(0)
      config.write
    end

    it 'converts object attributes to yaml' do
      YAML.should_receive(:dump).with(config.to_hash)
      config.to_yml
    end

    it 'converts object attributes to hash' do
      expect(config.to_hash).to be_kind_of(Hash)
      expect(config.to_hash).to include('regcode')
      expect(config.to_hash).to include('url')
      expect(config.to_hash).to include('language')
    end
  end

end
