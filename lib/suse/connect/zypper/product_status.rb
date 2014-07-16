# Product Extensions to give to YaST.
class SUSE::Connect::Zypper::ProductStatus

  REGISTRATION_STATUS_MESSAGES = ['Registered', 'Not Registered']

  attr_reader :installed_product

  def initialize(installed_product)
    @installed_product = installed_product
  end

  def registration_status
    registered? ? REGISTRATION_STATUS_MESSAGES.first : REGISTRATION_STATUS_MESSAGES.last
  end

  # Checks if the installed product is activated on the registration server
  def registered?
    !!remote_product
  end

  def related_activation
    return nil unless remote_product
    SUSE::Connect::Status.activations.find do |activation|
      activation.service.product == remote_product
    end
  end

  def remote_product
    SUSE::Connect::Status.activated_products.find do |remote_product|
      installed_product == remote_product
    end
  end

end
