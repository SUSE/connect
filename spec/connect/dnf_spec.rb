require 'spec_helper'

describe SUSE::Connect::Dnf do
  before do
    allow(SUSE::Connect::System).to receive(:filesystem_root).and_return nil
    allow(Object).to receive(:system).and_return true
  end

  subject { SUSE::Connect::Dnf }

  let(:os_release_file) { SUSE::Connect::Dnf::OS_RELEASE_FILE }
  let(:status) { object_double('Process Status', exitstatus: 0) }

  include_context 'shared lets'

  describe '.installed_products' do
    context :res7 do
      let(:os_release_content) { File.read('spec/fixtures/RES-os-release.txt') }

      it 'returns valid list of products based on proper XML' do
        expect(File).to receive(:exist?).with(os_release_file).and_return(true)
        allow(File).to receive(:read).with(os_release_file).and_return(os_release_content)
        expect(subject.installed_products.first.identifier).to eq 'RES'
      end

      it 'returns valid version' do
        expect(File).to receive(:exist?).with(os_release_file).and_return(true)
        allow(File).to receive(:read).with(os_release_file).and_return(os_release_content)
        expect(subject.installed_products.first.version).to eq '7'
      end

      it 'returns valid arch' do
        expect(File).to receive(:exist?).with(os_release_file).and_return(true)
        allow(File).to receive(:read).with(os_release_file).and_return(os_release_content)
        expect(subject.installed_products.first.arch).to eq 'unknown'
      end

      it 'returns proper base product' do
        expect(File).to receive(:exist?).with(os_release_file).and_return(true)
        allow(File).to receive(:read).with(os_release_file).and_return(os_release_content)
        expect(subject.base_product.identifier).to eq 'RES'
      end
    end
  end

  describe '.enable_repository' do
    let(:repository) { 'repository' }

    it 'enables dnf repository' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, "dnf config-manager --set-enabled #{repository}").and_return(['', '', status])
      subject.enable_repository(repository)
    end

    it 'raise an exception if repository not found' do
      exception = "SUSE::Connect::ZypperError: Repository #{repository} not found."
      expect(Open3).to receive(:capture3).with(shared_env_hash, "dnf config-manager --set-enabled #{repository}").and_raise(exception)
      expect { subject.enable_repository(repository) }.to raise_error("SUSE::Connect::ZypperError: Repository #{repository} not found.")
    end
  end

  describe '.disable_repository' do
    let(:repository) { 'repository' }

    it 'disables dnf repository' do
      expect(Open3).to receive(:capture3).with(shared_env_hash, "dnf config-manager --set-disabled #{repository}").and_return(['', '', status])
      subject.disable_repository(repository)
    end

    it 'raise an exception if repository not found' do
      exception = "SUSE::Connect::ZypperError: Repository #{repository} not found."
      expect(Open3).to receive(:capture3).with(shared_env_hash, "dnf config-manager --set-disabled #{repository}").and_raise(exception)
      expect { subject.disable_repository(repository) }.to raise_error("SUSE::Connect::ZypperError: Repository #{repository} not found.")
    end
  end

  describe '.repositories' do
    let(:dnf_helper_repo_output) { File.read('spec/fixtures/dnf_helper_repositories.json') }
    let(:dnf_helper_no_repo_output) { '[]' }
    let(:args) { "python3 #{SUSE::Connect::Dnf::HELPER_SCRIPT} --repos" }

    it 'lists all defined repositories' do
      expect(described_class).to receive(:execute)
                                   .with("python3 #{SUSE::Connect::Dnf::HELPER_SCRIPT} --repos", true, [0]).at_least(1)
                                   .and_return(dnf_helper_repo_output)

      expect(subject.repositories.size).to eq 11
      expect(subject.repositories.first.keys).to match_array(%i[alias name type priority enabled autorefresh gpgcheck url])
      expect(subject.repositories.map { |service| service[:name] })
        .to match_array(['Fedora 24 - x86_64 - Updates',
                         'Fedora 24 - x86_64 - Debug',
                         'Fedora 24 - x86_64',
                         'Fedora 24 - Test Updates Source',
                         'Fedora 24 - x86_64 - Test Updates',
                         'Fedora 24 - x86_64 - Test Updates Debug',
                         'Fedora 24 - Source', 'Fedora 24 - x86_64 - Updates - Debug',
                         'Fedora 24 - Updates Source', 'Fedora 24 openh264 (From Cisco) - x86_64',
                         'Fedora 24 openh264 (From Cisco) - x86_64 - Debug'])
    end

    it 'returns empty list when dnf has no repositories' do
      expect(described_class).to receive(:execute)
                                   .with("python3 #{SUSE::Connect::Dnf::HELPER_SCRIPT} --repos", true, [0]).at_least(1)
                                   .and_return(dnf_helper_no_repo_output)

      expect(subject.repositories.size).to eq 0
    end
  end

  describe '.read_service' do
    let(:service_name) { 'valid_service' }
    let(:service_url)  { 'http://example.com/access/service/666' }
    let(:login) { 'login' }
    let(:password) { 'password' }
    let(:system_credentials) { Credentials.new(login, password, Credentials::GLOBAL_CREDENTIALS_FILE) }
    let(:repo) do
      { alias: 'RES7',
        autorefresh: 'true',
        enabled: 'true',
        name: 'RES7',
        url: 'https://updates.suse.com/repo/$RCE/RES7/src?token' }
    end

    before do
      allow(Dnf).to receive(:config).at_least(1).and_return(Config.new)
      allow(Credentials).to receive(:read).with(Credentials::GLOBAL_CREDENTIALS_FILE).and_return(system_credentials)
      stub_request(:get, "http://#{login}:#{password}@example.com/access/service/666")
        .to_return(status: 200, body: File.read('spec/fixtures/service_response.xml'))
    end

    it 'returns a list of repositories' do
      service = subject.read_service(service_url)
      expect(service.size).to eq 2
      expect(service.first).to eq repo
    end
  end

end
