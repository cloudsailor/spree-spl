# frozen_string_literal: true

class RemoveSpartaDiscountService
  SPL_SOURCE_TYPE = 'SPL'

  def self.destroy_all_sparta_adjustments(order)
    order.line_items.each do |line_item|
      next unless line_item.adjustments.any? { |adj| adj.source_type == SPL_SOURCE_TYPE }

      adjustments = line_item.adjustments.where(source_type: SPL_SOURCE_TYPE)
      destroy_adjustments(adjustments, line_item, order)

      adjustments.where(source_type: SPL_SOURCE_TYPE).destroy_all
    end
  end

  def self.destroy_inactive_adjustments(adjustments, line_item, order)
    destroy_adjustments(adjustments, line_item, order)
    adjustments.where(eligible: true).update_all(eligible: false, state: 'close')

    line_item.reload
    ::Spree::Dependencies.cart_recalculate_service.constantize.call(order: order, line_item: line_item)

    adjustments.destroy_all
  end

  private_class_method def self.destroy_adjustments(adjustments, line_item, order)
    adjustments.where(eligible: true).update_all(eligible: false, state: 'close')

    line_item.reload
    ::Spree::Dependencies.cart_recalculate_service.constantize.call(order: order, line_item: line_item)
  end
end
