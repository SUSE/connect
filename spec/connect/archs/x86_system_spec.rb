require 'spec_helper'

class ClassicX86System
  class << self
    include SUSE::Connect::Archs::Any
    include SUSE::Connect::Archs::X86
  end
end

describe ClassicX86System do

  subject { described_class }

  it_behaves_like SUSE::Connect::Archs::X86

end
