# frozen_string_literal: true

module CheckoutControllerDecorator
  private

  def promotions_and_spl_adjustment_present?(order)
    order.promotions.any? && order.line_items.filter_map { |li| li.adjustments.where(source_type: 'SPL').present? }.any?
  end

  def promotion_switcher(order, check_only)
    PromotionSwitcherService.new(order, check_only).call
  end
end
