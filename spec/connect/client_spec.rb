require 'spec_helper'

describe SUSE::Connect::Client do

  subject { SUSE::Connect::Client.new({}) }

  describe '.new' do

    context :empty_opts do

      it 'should set port to default if it was not passed via constructor' do
        subject.options[:port].should eq subject.class::DEFAULT_PORT
      end

      it 'should set host to default if it was not passed via constructor' do
        subject.options[:host].should eq subject.class::DEFAULT_HOST
      end

      it 'should build url with default host and port' do
        subject.url.should eq "http://#{subject.class::DEFAULT_HOST}"
      end

    end

    context :passed_opts do

      subject { SUSE::Connect::Client.new({ :host => 'dummy', :port => '42' }) }

      it 'should set port to one from options if it was passed via constructor' do
        subject.options[:port].should eq '42'
      end

      it 'should set host to one from options if it was passed via constructor' do
        subject.options[:host].should eq 'dummy'
      end

      context :secure_requested do

        subject { SUSE::Connect::Client.new({ :host => 'dummy', :port => '443' }) }

        it 'should build url with https schema if passed 443 port' do
          subject.url.should eq 'https://dummy'
        end

      end

    end


  end

  describe '#execute!' do

    it 'should call announce if system not registered' do
      SUSE::Connect::System.stub(:registered? => false)
      subject.should_receive(:announce_system)
      subject.execute!
    end

    it 'should not call announce if system registered' do

      SUSE::Connect::System.stub(:registered? => true)
      subject.should_not_receive(:announce_system)
      subject.execute!
    end

    it 'should call activate_subscription' do
      SUSE::Connect::System.stub(:registered? => true)
      subject.should_receive(:activate_subscription)
      subject.execute!
    end

  end

end
