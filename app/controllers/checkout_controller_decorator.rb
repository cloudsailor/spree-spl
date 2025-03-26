# frozen_string_literal: true

module CheckoutControllerDecorator
  private

  def promotion_switcher(order, user, check_only)
    Rails.logger.debug "Promotion Switcher Service START #{user.email}, #{user.public_metadata}"
    PromotionSwitcherService.new(order, user, check_only).call
  end
end
