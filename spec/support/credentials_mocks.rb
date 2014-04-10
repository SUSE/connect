def mock_dry_file

  let :source_cred_file do
    opened_file = double('me_file')
    opened_file.stub(:puts => true)
    opened_file.stub(:close => true)
    opened_file
  end

  let :params do
    %w{ Kif Kroker ha }
  end

  # TODO: Mock it explicitly by path
  before(:each) do
    File.stub(:open => source_cred_file)
    File.any_instance.stub(:puts => true)
    Dir.stub(:mkdir => true)
    SUSE::Connect::System.stub(:credentials => %w{ dummy tummy })
  end

end

def fixtures_dir
  File.expand_path('../../fixtures', __FILE__)
end
