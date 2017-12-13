require 'etc'
# implementing interface to ~/.curlrc which can hold proxy details
class SUSE::Toolkit::CurlrcDotfile
  CURLRC_LOCATION = '.curlrc'

  def initialize
    @file_location = File.join(Etc.getpwuid.dir, CURLRC_LOCATION)
  end

  def exist?
    File.exist?(@file_location)
  end

  def username
    line_with_credentials.match(/--proxy-user\s?"(.*):/)[1] rescue nil
  end

  def password
    line_with_credentials.match(/--proxy-user\s?".*:(.*)"/)[1] rescue nil
  end

  private

  def line_with_credentials
    return nil unless exist?
    @line_with_credentials ||= File.readlines(@file_location).find { |l| l =~ /--proxy-user ".*:.*"/ }
  end
end
