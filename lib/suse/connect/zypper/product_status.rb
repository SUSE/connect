# Product Extensions to give to YaST.
class SUSE::Connect::Zypper::ProductStatus
  REGISTRATION_STATUS_MESSAGES = ['Registered', 'Not Registered']

  attr_reader :installed_product

  def initialize(installed_product, status)
    @installed_product = installed_product
    @status            = status
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
    @status.activations.find do |activation|
      activation.service.product == remote_product
    end
  end

  def remote_product
    @status.activated_products.find do |remote_product|
      installed_product == remote_product
    end
  end

  # There can be the case that SCC/Proxies send empty values for subscription
  # information in an activation. Do not handle them as activation with subscription
  # associated.
  def has_subscription_associated?
    return false unless related_activation

    related_activation[:regcode] != nil
  end
end
