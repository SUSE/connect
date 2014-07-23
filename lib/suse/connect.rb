module SUSE

  require 'suse/toolkit/system_calls'
  require 'suse/toolkit/curlrc_dotfile'

  # All modules and classes of Connected nested
  module Connect

    require 'suse/connect/version'
    require 'suse/connect/logger'
    require 'suse/connect/errors'

    module Archs
      require 'suse/connect/archs/generic'
      arch = Class.new{ extend SUSE::Connect::Archs::Generic; extend SUSE::Toolkit::SystemCalls }.arch
      require "suse/connect/archs/#{arch}"
    end

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
    require 'suse/connect/zypper/product_status'

    # Holding all the object classes received from registration server
    module Remote
      require 'suse/connect/remote/server_driven_model'
      require 'suse/connect/remote/product'
      require 'suse/connect/remote/service'
      require 'suse/connect/remote/subscription'
      require 'suse/connect/remote/activation'
    end

    # Zypper module holding extracted functionality and classes
    # related
    module Zypper
      require 'suse/connect/zypper/product'
    end

  end

end
