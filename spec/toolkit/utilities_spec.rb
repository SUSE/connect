require 'spec_helper'

# Into this class instance we include subject module
class DummyReceiver
  include SUSE::Toolkit::Utilities
end

describe SUSE::Toolkit::Utilities do
  subject { DummyReceiver.new }

  describe '?token_auth' do
    it 'returns string for auth header' do
      expect(subject.send(:token_auth, 'lambada')).to eq 'Token token=lambada'
    end

    it 'not raising if no token passed, but method requested' do
      expect { subject.send(:token_auth, nil) }.not_to raise_error
    end
  end

  describe '?basic_auth' do
    it 'returns string for auth header' do
      allow(Credentials).to receive_messages(:read => Credentials.new('bob', 'dylan'))
      base64_line = 'Basic Ym9iOmR5bGFu'
      expect(subject.send(:system_auth)).to eq base64_line
    end

    it 'raise if cannot get credentials' do
      allow(Credentials).to receive(:read).and_raise(Errno::ENOENT)
      expect { subject.send(:system_auth) }
        .to raise_error CannotBuildBasicAuth,
                        "\nCannot read username and password from #{SUSE::Connect::Credentials::GLOBAL_CREDENTIALS_FILE}."
    end

    it 'raise if nil credentials' do
      allow(Credentials).to receive(:read).and_return(Credentials.new(nil, nil))
      expect { subject.send(:system_auth) }
        .to raise_error CannotBuildBasicAuth,
                        "\nCannot read username and password from #{SUSE::Connect::Credentials::GLOBAL_CREDENTIALS_FILE}."
    end
  end
end
