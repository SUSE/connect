require 'spec_helper'

# dummy system which should be tested that it behaves like X8664 system
class ClassicX86System
  class << self
    include SUSE::Connect::Archs::Generic
    include SUSE::Connect::Archs::X86_64
  end
end

describe ClassicX86System do

  subject { described_class }

  it_behaves_like SUSE::Connect::Archs::X86_64

end
