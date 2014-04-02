require 'spec_helper'

describe SUSE::Connect::Yast::Extension do

  subject do
    extension_attrs = [
        'SLEEK',
        'SUSE LINUX ENTERPRISE EXTENSION KDE',
        'SLEEK puts the modern yet familiar GUI back into SLE that you love',
        'SLEEK-12'
    ]
    SUSE::Connect::Yast::Extension.new(*extension_attrs)
  end
  it 'has attribute short_name' do
    expect(subject.short_name).not_to be_nil
  end

  it 'has attribute long_name' do
    expect(subject.long_name).not_to be_nil
  end

  it 'has attribute description' do
    expect(subject.description).not_to be_nil
  end

  it 'has attribute product_ident' do
    expect(subject.product_ident).not_to be_nil
  end
end
