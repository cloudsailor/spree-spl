# frozen_string_literal: true

module CheckoutControllerDecorator
  private

  def promotion_switcher(order, user, check_only)
    PromotionSwitcherService.new(order, user, check_only).call
  end
end
