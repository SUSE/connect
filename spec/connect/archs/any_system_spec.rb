require 'spec_helper'

# Any system which should behave as generic one
class AnySystem
  class << self
    include SUSE::Connect::Archs::Generic
  end
end

describe AnySystem do

  subject { described_class }

  it_behaves_like SUSE::Connect::Archs::Generic

end
