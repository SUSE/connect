module SUSE
  module Connect
    # System class allowing to interact with underlying system
    class System
      class << self

        include SUSE::Toolkit::SystemCalls
        include SUSE::Connect::Archs::Any
        #include "SUSE::Connect::Archs::#{self.arch.constantize}"

      end
    end
  end
end
