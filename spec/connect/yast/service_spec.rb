require 'spec_helper'

describe SUSE::Connect::YaST::Service do

  subject { SUSE::Connect::YaST::Service.new(
      "Test Service", "http://test.com/service/")
  }

  it 'has attribute url' do
    #subject.instance_variables.contains("@url")
    expect(subject.url).not_to be_nil
  end

  it 'has attribute name' do
    #subject.instance_variables.contains("@url")
    expect(subject.name).not_to be_nil
  end
end
