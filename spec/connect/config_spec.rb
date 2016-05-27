require 'spec_helper'
require 'rubygems'

describe SUSE::Connect::Config do
  let(:config_file) { File.expand_path File.join(File.dirname(__FILE__), '../fixtures/SUSEConnect') }
  let(:config) { described_class.new(config_file) }

  describe '.serializable_attributes' do
    let(:attrs) { %i(baz buz) }
    subject { described_class.serializable_attributes(*attrs) }
    it { expect { subject }.to change(described_class, :serializable).to attrs }

    after { described_class.serializable_attributes :url, :insecure, :language }
  end

  describe '#initialize' do
    subject { config }

    its(:regcode)                    { is_expected.to eq 'regcode' }
    its(:url)                        { is_expected.to eq 'https://test.scc.suse.com' }
    its(:language)                   { is_expected.to eq 'EN' }
    its(:post_register_scripts_path) { is_expected.to eq '/some/path' }

    context 'with different config file location' do
      let(:config_file) { '/tmp/SUSEConnect' }
      it 'stores the location' do
        expect(config.instance_variable_get(:@file)).to eq '/tmp/SUSEConnect'
      end
    end

    context 'when file does not exist' do
      let(:config_file)                { '/non-existing-file' }

      its(:language)                   { is_expected.to be_nil }
      its(:url)                        { is_expected.to eq described_class::DEFAULT_URL }
      its(:post_register_scripts_path) { is_expected.to eq described_class::DEFAULT_POST_REGISTER_SCRIPTS_PATH }
      its(:insecure)                   { is_expected.to be_falsy }
    end
  end

  describe '#merge' do
    it 'overwrites attributes from passed hash' do
      allow_any_instance_of(described_class).to receive(:read).and_return('insecure' => :stubval)
      conf = described_class.new
      expect(conf.insecure).to eq :stubval
      conf.merge!(:insecure => :goo)
      expect(conf.insecure).to eq :goo
    end

    it 'ignores unknown for config keys' do
      allow_any_instance_of(described_class).to receive(:read).and_return('insecure' => :base_value)
      conf = described_class.new
      expect(conf.insecure).to eq :base_value
      conf.merge!(:insecure => :goo, :logger => :base)
      expect(conf.insecure).to eq :goo
    end

    it 'properly serializes new merged values' do
      allow_any_instance_of(described_class).to receive(:read).and_return('insecure' => :base_value)
      conf = described_class.new
      conf.merge!(
        :url => 'http://smt.domain.local',
        :language => 'DE',
        :insecure => true,
        :filesystem_root => '/docker/pool/2'
      )
      expect(conf.select_serializable_attributes).to eq(
        'url' => 'http://smt.domain.local',
        'insecure' => true,
        'language' => 'DE'
      )
    end
  end

  describe '#merge!' do
    it 'updates config attributes from overrides hash' do
      overrides = { url: 'http://foo.bar', insecure: true }
      config.merge!(overrides)

      expect(config.url).to eq overrides[:url]
      expect(config.insecure).to eq overrides[:insecure]
    end

    it 'does not override config attributes with nil values' do
      overrides = { url: nil, insecure: nil }
      config.merge!(overrides)

      expect(config.url).to eq 'https://test.scc.suse.com'
      expect(config.insecure).to eq false
    end
  end

  describe '#write' do
    it 'writes configuration settings to YAML file' do
      expect(File).to receive(:write).with(config_file, config.to_yaml).and_return(0)
      config.write!
    end
  end

  describe '#to_yaml' do
    it 'converts object attributes to yaml' do
      expect(YAML.load(config.to_yaml)).to_not be_empty
    end

    it 'only converts serializable attributes to YAML' do
      config.regcode  = 'CRYTOP'
      expect(config.send(:select_serializable_attributes)).to_not include 'regcode'
    end
  end
end
