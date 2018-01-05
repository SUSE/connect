require 'spec_helper'
require 'rubygems'

describe SUSE::Connect::Config do
  let(:config_file) { File.expand_path File.join(File.dirname(__FILE__), '../fixtures/SUSEConnect') }

  context 'class methods' do
    subject { SUSE::Connect::Config }

    after do
      subject.serializable_attributes :url, :insecure, :language, :namespace
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
        expect(config.url).to eq 'https://scc.suse.com'
        expect(config.language).to eq 'EN'
      end

      it 'is empty if file does not exist' do
        config = subject.new('/non-existing-file')
        expect(config.language).to be_nil
      end

      it 'uses default url in case if ' do
        config = subject.new('/non-existing-file')
        expect(config.url).to eq SUSE::Connect::Config::DEFAULT_URL
      end

      it 'sets insecure to false if it is not set' do
        allow_any_instance_of(subject).to receive(:read).and_return(foo: :bar)
        config = subject.new
        expect(config.insecure).to be false
      end
    end

    describe '#merge' do
      it 'overwrites attributes from passed hash' do
        allow_any_instance_of(subject).to receive(:read).and_return('insecure' => :stubval)
        conf = subject.new
        expect(conf.insecure).to eq :stubval
        conf.merge!(insecure: :goo)
        expect(conf.insecure).to eq :goo
      end

      it 'ignores unknown for config keys' do
        allow_any_instance_of(subject).to receive(:read).and_return('insecure' => :base_value)
        conf = subject.new
        expect(conf.insecure).to eq :base_value
        conf.merge!(insecure: :goo, logger: :base)
        expect(conf.insecure).to eq :goo
      end

      it 'properly serializes new merged values' do
        allow_any_instance_of(subject).to receive(:read).and_return('insecure' => :base_value)
        conf = subject.new
        conf.merge!(
          url: 'http://smt.domain.local',
          language: 'DE',
          insecure: true,
          filesystem_root: '/docker/pool/2'
        )
        expect(conf.select_serializable_attributes).to eq(
          'url' => 'http://smt.domain.local',
          'insecure' => true,
          'language' => 'DE'
        )
      end
    end

    context '#merge!' do
      it 'updates config attributes from overrides hash' do
        expect(config.url).to eq 'https://scc.suse.com'
        expect(config.insecure).to eq false

        overrides = { url: 'http://foo.bar', insecure: true }
        config.merge!(overrides)

        expect(config.url).to eq overrides[:url]
        expect(config.insecure).to eq overrides[:insecure]
      end

      it 'does not override config attributes with nil values' do
        expect(config.url).to eq 'https://scc.suse.com'
        expect(config.insecure).to eq false

        overrides = { url: nil, insecure: nil }
        config.merge!(overrides)

        expect(config.url).to eq 'https://scc.suse.com'
        expect(config.insecure).to eq false
      end
    end

    context '#write' do
      it 'writes configuration settings to YAML file' do
        expect(File).to receive(:write).with(config_file, config.to_yaml).and_return(0)
        config.write!
      end
    end

    context '#to_yaml' do
      it 'converts object attributes to yaml' do
        expect(YAML.load(config.to_yaml)).to_not be_empty
      end

      it 'only converts serializable attributes to YAML' do
        config.regcode = 'CRYTOP'
        expect(config.send(:select_serializable_attributes)).to_not include 'regcode'
      end
    end
  end
end
