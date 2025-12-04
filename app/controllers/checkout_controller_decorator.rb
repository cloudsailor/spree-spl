# frozen_string_literal: true

module CheckoutControllerDecorator
  def self.prepended(base)
    base.before_action :promotion_switcher
  end

  private

  def promotion_switcher
    PromotionSwitcherService.new(@order, false).call
  end
end
