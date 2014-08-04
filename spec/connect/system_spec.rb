require 'spec_helper'

describe SUSE::Connect::System do

  subject { described_class }

  context :x86 do
    it_behaves_like SUSE::Connect::Archs::Generic
    it_behaves_like SUSE::Connect::Archs::X86_64
  end


end
