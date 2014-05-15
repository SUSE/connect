require 'spec_helper'

describe SUSE::Connect::Product do

  subject do
    extension = {
      'name' => 'SLEEK',
      'long_name' => 'SUSE LINUX ENTERPRISE EXTENSION KDE',
      'description' => 'SLEEK puts the modern yet familiar GUI back into SLE that you love',
      'zypper_name' => 'SLEEK-12',
      'zypper_version' => '12',
      'arch' => 'x86_64',
      'free' => true,
      'eula_url' => 'https://nu.novell.com/SUSE:/Products:/SLE-12/images/' \
        'repo/SLE-12-module-sleek-POOL-x86_64-Media.license/'
      }
    SUSE::Connect::Product.new(extension)
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

  it 'has attribute version' do
    expect(subject.version).not_to be_nil
  end

  it 'has attribute arch' do
    expect(subject.arch).not_to be_nil
  end

  it 'has attribute eula_url' do
    expect(subject.eula_url).not_to be_nil
  end

end
