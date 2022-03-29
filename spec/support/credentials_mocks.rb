def mock_dry_file
  let :source_cred_file do
    opened_file = double('me_file')
    allow(opened_file).to receive(:puts).and_return true
    allow(opened_file).to receive(:close).and_return true
    opened_file
  end

  let(:params) { %w[Kif Kroker ha] }

  # TODO: Mock it explicitly by path
  before(:each) do
    allow(File).to receive(:open).and_return source_cred_file
    allow_any_instance_of(File).to receive(:puts).and_return true
    allow(Dir).to receive(:mkdir).and_return true
    allow(SUSE::Connect::System).to receive(:credentials).and_return Credentials.new('dummy', 'tummy', 'yummy')
  end
end

def fixtures_dir
  File.expand_path('../../fixtures', __FILE__)
end
