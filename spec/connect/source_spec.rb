require 'spec_helper'

describe SUSE::Connect::Source do

  subject { SUSE::Connect::Source.new('Test Service', 'http://test.com/service/') }

  it 'has attribute url' do
    expect(subject.url).not_to be_nil
  end

  it 'has attribute name' do
    expect(subject.name).not_to be_nil
  end

end
