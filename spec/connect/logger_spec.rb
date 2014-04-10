require 'spec_helper'
require 'logger'
require 'stringio'

describe SUSE::Connect::GlobalLogger do
  it 'the default logger is a Logger instance' do
    expect(GlobalLogger.instance.log).to be_a_kind_of(::Logger)
  end
end

describe SUSE::Connect::Logger do
  before do
    # define a testing class
    class LoggerTest
      include SUSE::Connect::Logger

      def self.test_class_logging
        log.debug 'msg'
        log.info 'msg'
        log.warn 'msg'
        log.error 'msg'
        log.fatal 'msg'
      end

      def test_logging
        log.debug 'msg'
        log.info 'msg'
        log.warn 'msg'
        log.error 'msg'
        log.fatal 'msg'
      end
    end
  end

  it 'provides logging mechanism for class methods' do
    expect { LoggerTest.test_class_logging }.not_to raise_error
  end

  it 'provides logging mechanism for instance methods' do
    expect { LoggerTest.new.test_logging }.not_to raise_error
  end
end

describe SUSE::Connect::DefaultLogger do
  it 'by default does not log debug messages' do
    stringio = StringIO.new
    default_logger = SUSE::Connect::DefaultLogger.new(stringio)

    default_logger.debug 'TEST'
    expect(stringio.string).to eq ''
  end

  it 'logs only the message without extra data or formatting' do
    stringio = StringIO.new
    default_logger = SUSE::Connect::DefaultLogger.new(stringio)

    default_logger.warn 'TEST'
    expect(stringio.string).to eq "TEST\n"
  end
end
