require 'spec_helper'

describe SUSE::Connect::YaST do

  subject { SUSE::Connect::YaST }

  let(:options) { { token: 'regcode', email: 'foo@bar.zer' } }
  let(:client) { mock 'client' }

  describe '#announce_system' do

    before do
      Client.stub(:new).and_return(client)
      client.stub :announce_system
    end

    it 'calls announce_system on an instance of Client' do
      client.should_receive :announce_system
      subject.announce_system
    end

    it 'forwards all params to Client.announce_system' do
      Client.should_receive(:new).with(options).and_return(client)
      subject.announce_system(options)
    end

    it 'falls to use an empty hash as params if none are specified' do
      Client.should_receive(:new).with({}).and_return(client)
      subject.announce_system
    end

  end

end
