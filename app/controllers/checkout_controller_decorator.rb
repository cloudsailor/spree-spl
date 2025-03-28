# frozen_string_literal: true

module CheckoutControllerDecorator
  private

  def promotion_switcher(order, user, check_only)
    Rails.logger.debug order.public_metadata[:spl_no_card] if order.public_metadata.key?(:spl_no_card)
    PromotionSwitcherService.new(order, user, check_only).call
  end
end
