
require 'openssl'

require 'suse/toolkit/system_calls'

module SUSE
  module Connect

    # helper methods for managing the SSL certificates
    class SSLCertificate
      extend SUSE::Toolkit::SystemCalls
      extend Logger

      # where to save the imported certificate
      SERVER_CERT_FILE = '/usr/share/pki/trust/anchors/registration_server.pem'

      # script for updating the system certificates
      UPDATE_CERTIFICATES = '/usr/sbin/update-ca-certificates'

      # compute SHA1 fingerprint of a certificate
      # @param cert [OpenSSL::X509::Certificate] the certificate
      # @return [String] fingerprint in "AB:CD:EF:..." format
      def self.sha1_fingerprint(cert)
        OpenSSL::Digest::SHA1.new(cert.to_der).to_s.upcase.scan(/../).join(':')
      end

      # import the SSL certificate into the system
      # @see https://github.com/openSUSE/ca-certificates
      # @param cert [OpenSSL::X509::Certificate] the certificate
      def self.import(cert)
        log.info "Writing a SSL certificate to #{SERVER_CERT_FILE} file..."
        File.write(SERVER_CERT_FILE, cert.to_pem)

        # update the symlinks
        log.info "Executing #{UPDATE_CERTIFICATES}..."
        call_with_output(UPDATE_CERTIFICATES)
      end
    end

  end
end
