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
  let(:stringio) { StringIO.new }
  let(:default_logger) { SUSE::Connect::DefaultLogger.new(stringio) }

  it 'by default does not log debug messages' do
    default_logger.debug 'TEST'
    expect(stringio.string).to eq ''
  end

  it 'logs only the message without extra data or formatting' do
    default_logger.warn 'TEST'
    expect(stringio.string).to eq "TEST\n"
  end

  it 'logs in green font' do
    default_logger.info 'TEST'.log_green
    expect(stringio.string).to eq "\e[32mTEST\e[0m\n"
  end

  it 'logs in red font' do
    default_logger.info 'TEST'.log_red
    expect(stringio.string).to eq "\e[31mTEST\e[0m\n"
  end

  it 'logs in bold font' do
    default_logger.info 'TEST'.bold
    expect(stringio.string).to eq "\e[1mTEST\e[22m\n"
  end
end
