# frozen_string_literal: true

module CheckoutControllerDecorator
  private

  def promotion_switcher(order, check_only)
    PromotionSwitcherService.new(order, check_only).call
  end
end
