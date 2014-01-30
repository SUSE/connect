require 'spec_helper'

describe SUSE::Connect::Logger do

  subject { SUSE::Connect::Logger }

  describe '.info' do

    it 'should put passed argument to STDOUT' do
      STDOUT.should_receive(:puts).with('i am gecko')
      subject.info 'i am gecko'
    end

  end

  describe '.error' do

    it 'should put passed argument to STDERR' do
      STDERR.should_receive(:puts).with('ERROR: i am broken')
      subject.error 'i am broken'
    end

  end

  describe '.error' do

    it 'should put passed argument to STDOUT' do
      STDOUT.should_receive(:puts).with('DEBUG: using looking glass')
      subject.debug 'using looking glass'
    end

  end


end
