module SUSE
  # All modules and classes of Connected nested
  module Connect

    # shared modules
    require 'suse/connect/comparable_product'

    require 'suse/connect/version'
    require 'suse/connect/logger'
    require 'suse/connect/errors'
    require 'suse/connect/client'
    require 'suse/connect/system'
    require 'suse/connect/product'
    require 'suse/connect/zypper'
    require 'suse/connect/service'
    require 'suse/connect/source'
    require 'suse/connect/connection'
    require 'suse/connect/credentials'
    require 'suse/connect/config'
    require 'suse/connect/api'
    require 'suse/connect/yast'
    require 'suse/connect/ssl_certificate'
    require 'suse/connect/status'
    require 'suse/connect/server_driven_model'
    require 'suse/connect/reg_server_product'
    require 'suse/connect/reg_server_subscription'

  end
end
