RSpec.shared_examples 'server driven model' do
  subject { described_class }

  let(:config) { SUSE::Connect::Config.new }
  let(:client) { SUSE::Connect::Client.new(config) }

  describe '.initialize' do
    it 'sets all the passed attributes assumed it is hash' do
      instance = subject.new(client, 'foo' => 'bar')
      expect(instance.foo).to eq 'bar'
    end

    it 'sets all the passed attributes assumed it is hash' do
      instance = subject.new(client, 'foo' => ['dabei'])
      expect(instance.foo).to eq ['dabei']
    end

    it 'raises error if not hash passed to initializer' do
      expect { subject.new(client, :foo) }.to raise_error ArgumentError, /Only Hash instance accepted/
    end
  end
end
