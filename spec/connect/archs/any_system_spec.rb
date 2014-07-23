require 'spec_helper'

class AnySystem
  class << self
    include SUSE::Connect::Archs::Any
  end
end

describe AnySystem do

  subject { described_class }

  it_behaves_like SUSE::Connect::Archs::Any

end
