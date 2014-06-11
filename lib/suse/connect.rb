module SUSE
  # All modules and classes of Connected nested
  module Connect

    require 'suse/connect/version'
    require 'suse/connect/logger'
    require 'suse/connect/errors'
    require 'suse/connect/client'
    require 'suse/connect/system'
    require 'suse/connect/connection'
    require 'suse/connect/credentials'
    require 'suse/connect/config'
    require 'suse/connect/api'
    require 'suse/connect/yast'
    require 'suse/connect/ssl_certificate'
    require 'suse/connect/status'
    require 'suse/connect/zypper'

    # Holding all the object classes received from registration server
    module Remote
      require 'suse/connect/remote/server_driven_model'
      require 'suse/connect/remote/product'
      require 'suse/connect/remote/service'
      require 'suse/connect/remote/subscription'
    end

    # Zypper module holding extracted functionality and classes
    # related
    module Zypper
      require 'suse/connect/zypper/product'
    end

  end
end
