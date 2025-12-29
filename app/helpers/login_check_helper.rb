# frozen_string_literal: true

module LoginCheckHelper
  # Checks if user is logged to SPL basing on local information
  # @param user [Spree::User]
  # @return [true, false]
  def self.logged?(user)
    return false unless user&.private_metadata&.fetch('spl_access_token', nil)

    true
  end
end
