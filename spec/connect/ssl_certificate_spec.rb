require 'spec_helper'

describe SUSE::Connect::SSLCertificate do
  subject { SUSE::Connect::SSLCertificate }
  let(:test_cert) { File.read(File.join(fixtures_dir, 'test.pem')) }

  describe '.sha1_fingerprint' do
    it 'returns the certificate SHA1 fingerprint' do
      cert = OpenSSL::X509::Certificate.new(test_cert)
      # obtained via "openssl x509 -noout -in spec/fixtures/test.pem -fingerprint"
      sha1 = 'A8:DE:08:B1:57:52:FE:70:DF:D5:31:EA:E3:53:BB:39:EE:01:FF:B9'

      expect(SUSE::Connect::SSLCertificate.sha1_fingerprint(cert)).to eq(sha1)
    end
  end

  describe '.import' do
    it 'writes the PEM certificate into the system and activates it' do
      cert = OpenSSL::X509::Certificate.new(test_cert)

      expect(File).to receive(:exist?).with(
        SUSE::Connect::SSLCertificate::SERVER_CERT_FILE
      ).and_return(false)

      expect(File).to receive(:write).with(
        SUSE::Connect::SSLCertificate::SERVER_CERT_FILE,
        cert.to_pem
      )

      expect(SUSE::Connect::SSLCertificate).to(receive(:call_with_output)
        .with('/usr/sbin/update-ca-certificates'))

      SUSE::Connect::SSLCertificate.import(cert)
    end
  end

end
