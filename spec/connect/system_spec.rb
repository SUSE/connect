require 'spec_helper'

describe SUSE::Connect::System do

  subject { described_class }

  it_behaves_like SUSE::Connect::Archs::Generic

end
