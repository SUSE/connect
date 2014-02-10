require 'spec_helper'
require 'suse/connect/cli'

describe SUSE::Connect::Cli do

  subject { SUSE::Connect::Cli }

  describe '#execute!' do

    it 'should produce log output' do
      Logger.should_receive(:error).with('no registration token provided')
      Client.any_instance.stub(:execute!).and_raise CannotBuildTokenAuth
      cli = subject.new({})
      cli.should_receive(:exit).and_return(true)
      cli.execute!
    end

  end


end
