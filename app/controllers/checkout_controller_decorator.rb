# frozen_string_literal: true

module CheckoutControllerDecorator
  def self.prepended(base)
    base.before_action :promotion_switcher
  end

  private

  def promotion_switcher
    PromotionSwitcherService.new(@order, true).call
    return unless @order.line_items.any? { |line_item| line_item.adjustments.exists?(source_type: 'SPL') }

    @order.line_items.each do |line_item|
      adjustments_to_remove = line_item.adjustments.reject { |adj| adj.source_type == 'SPL' }
      adjustments_to_remove.each(&:destroy)
    end
  end
end
