require 'spec_helper'

describe SUSE::Connect::SSLCertificate do
  subject { SUSE::Connect::SSLCertificate }
  let(:test_cert) { File.read(File.join(fixtures_dir, 'test.pem')) }
  include_context 'shared lets'

  describe '.sha1_fingerprint' do
    it 'returns the certificate SHA1 fingerprint' do
      cert = OpenSSL::X509::Certificate.new(test_cert)
      # obtained via "openssl x509 -noout -in spec/fixtures/test.pem -fingerprint"
      sha1 = 'A8:DE:08:B1:57:52:FE:70:DF:D5:31:EA:E3:53:BB:39:EE:01:FF:B9'

      expect(SUSE::Connect::SSLCertificate.sha1_fingerprint(cert)).to eq(sha1)
    end
  end

  describe '.sha256_fingerprint' do
    it 'returns the certificate SHA256 fingerprint' do
      cert = OpenSSL::X509::Certificate.new(test_cert)
      # obtained via "openssl x509 -in spec/fixtures/test.pem -outform DER | sha256sum"
      sha256 = '2A:02:DA:EC:A9:FF:4C:B4:A6:C0:57:08:F6:1C:8B:B0:94:FA:F4:60:96:5E:18:48:CA:84:81:48:60:F3:CB:BF'

      expect(SUSE::Connect::SSLCertificate.sha256_fingerprint(cert)).to eq(sha256)
    end
  end

  describe '.import' do

    let(:cert) { OpenSSL::X509::Certificate.new(test_cert) }

    it 'writes the PEM certificate into the system and activates it' do

      expect(File).to receive(:exist?).with(
        SUSE::Connect::SSLCertificate::SERVER_CERT_FILE
      ).and_return(false)

      expect(File).to receive(:write).with(
        SUSE::Connect::SSLCertificate::SERVER_CERT_FILE,
        cert.to_pem
      )

      expect(SUSE::Connect::SSLCertificate).to(receive(:execute)
        .with('/usr/sbin/update-ca-certificates'))

      SUSE::Connect::SSLCertificate.import(cert)
    end

    it 'gets to the underlying open3 call' do

      allow(File).to receive(:exist?).with(
                          SUSE::Connect::SSLCertificate::SERVER_CERT_FILE
                      ).and_return(false)

      allow(File).to receive(:write).with(
                          SUSE::Connect::SSLCertificate::SERVER_CERT_FILE,
                          cert.to_pem
                      )

      expect(Open3).to receive(:capture3).with(shared_env_hash, '/usr/sbin/update-ca-certificates')
                           .and_return(['', '', double(:exitstatus => 0)])

      SUSE::Connect::SSLCertificate.import(cert)
    end

  end

end
