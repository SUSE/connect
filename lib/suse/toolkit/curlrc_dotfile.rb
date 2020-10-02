require 'etc'

# When configuring a proxy with "yast2 proxy", the proxy url is written to ~/.curlrc
# and /etc/sysconfig/proxy. The proxy credentials are only written to ~/.curlrc.
# At login session init, the values from /etc/sysconfig/proxy are set in the environment,
# from where Net::Http is picking them up. Unfortunately the proxy credentials are
# not prepended to the proxy url, but stored seperately in .curlrc. Net::Http isn't picking
# them up automatically from there, that's why we need to parse them manually from .curlrc

class SUSE::Toolkit::CurlrcDotfile
  CURLRC_LOCATION = '.curlrc'

  # Yast is setting up the credentials in ~/.curlrc in '--proxy-user "user:pwd"' style,
  # but https://www.suse.com/support/kb/doc/?id=000017441 uses 'proxy-user = "john:n0v3ll"'.
  # SUSEConnect should be capable of reading both formats
  CURLRC_CREDENTIALS_REGEXP = /-*proxy-user[ =]*"(.+):(.+)"/

  def initialize
    @file_location = File.join(Etc.getpwuid.dir, CURLRC_LOCATION)
  end

  def exist?
    File.exist?(@file_location)
  end

  def username
    line_with_credentials.match(CURLRC_CREDENTIALS_REGEXP)[1] rescue nil
  end

  def password
    line_with_credentials.match(CURLRC_CREDENTIALS_REGEXP)[2] rescue nil
  end

  private

  def line_with_credentials
    return nil unless exist?
    @line_with_credentials ||= File.readlines(@file_location).find { |l| l =~ CURLRC_CREDENTIALS_REGEXP }
  end
end
