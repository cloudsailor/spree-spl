# frozen_string_literal: true

module CheckoutControllerDecorator
  def self.prepended(base)
    base.before_action :promotion_switcher
  end

  private

  def promotion_switcher
    if request.url.include?('confirm')
      PromotionSwitcherService.new(@order, false).call
    else
      PromotionSwitcherService.new(@order, true).call
    end
  end
end
