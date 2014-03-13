module SUSE
  # All modules and classes of Connected nested
  module Connect

    UUIDFILE                = '/sys/class/dmi/id/product_uuid'
    UUIDGEN_LOCATION        = '/usr/bin/uuidgen'
    ZYPPER_CREDENTIALS_DIR  = '/etc/zypp/credentials.d'
    CREDENTIALS_NAME        = 'SCCcredentials'
    NCC_CREDENTIALS_FILE    = File.join(ZYPPER_CREDENTIALS_DIR, CREDENTIALS_NAME)

    require 'suse/connect/version'
    require 'suse/connect/logger'
    require 'suse/connect/errors'
    require 'suse/connect/client'
    require 'suse/connect/system'
    require 'suse/connect/zypper'
    require 'suse/connect/service'
    require 'suse/connect/connection'
    require 'suse/connect/api'
  end
end
