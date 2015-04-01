RSpec.shared_context 'shared lets', :a => :b do
  let(:shared_env_hash) { { 'LC_ALL' => 'C' } }
end
