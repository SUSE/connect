require 'etc'

# Yast is not adding proxy credentials to the 'http_proxy' env variable, but writing
# them to ~/.curlrc. This class is parsing the credentials from there to be used in connection.rb
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
    @line_with_credentials ||= File.readlines(@file_location).find { |l| l =~ /--proxy-user ".*:.*"/ }
  end
end
