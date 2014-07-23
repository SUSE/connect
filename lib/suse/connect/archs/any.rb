require 'suse/toolkit/system_calls'

module SUSE::Connect::Archs::Any

  attr_accessor :filesystem_root

  def prefix_path(path)
    filesystem_root ? File.join(filesystem_root, path) : path
  end

  def hwinfo
    {
      hostname: hostname,
      arch: arch
    }
  end

  # returns username and password from SCC_CREDENTIALS_FILE
  #
  # == Returns:
  # Credentials object or nil
  #
  def credentials
    if File.exist?(Credentials.system_credentials_file)
      Credentials.read(Credentials.system_credentials_file)
    else
      nil
    end
  end

  def credentials?
    !!credentials
  end

  # Checks if system activations includes base product
  def activated_base_product?
    credentials? && Status.activated_products.include?(Zypper.base_product)
  end

  def remove_credentials
    File.delete Credentials.system_credentials_file if credentials?
  end

  def add_service(service)
    raise ArgumentError, 'only Remote::Service accepted' unless service.is_a? Remote::Service
    Zypper.remove_service(service.name)
    Zypper.add_service(service.url, service.name)
    Zypper.write_service_credentials(service.name)
    Zypper.refresh_services
    service
  end

  def hostname
    hostname = Socket.gethostname
    if hostname && hostname != '(none)'
      hostname
    else
      Socket.ip_address_list.find {|intf| intf.ipv4_private? }.ip_address
    end
  end

  # def x86?
  #   %w{x86, x86_64}.include? arch
  # end

  def arch
    execute('uname -i', false)
  end

end
