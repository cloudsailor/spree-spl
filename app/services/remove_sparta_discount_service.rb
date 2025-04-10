# frozen_string_literal: true

class RemoveSpartaDiscountService
  def initialize(order)
    @line_items = order.line_items
    @order = order
  end

  def call
    line_items.each do |line_item|
      next unless line_item.adjustments.any? { |adj| adj.source_type == 'SPL' }

      remove_sparta_adjustment(line_item)
    end
  end

  private

  attr_accessor :line_items, :order

  def remove_sparta_adjustment(line_item)
    line_item.adjustments.where(source_type: 'SPL', eligible: true).update_all(eligible: false, state: 'close')

    line_item.reload
    ::Spree::Dependencies.cart_recalculate_service.constantize.call(order: order, line_item: line_item)
    line_item.adjustments.where(source_type: 'SPL').destroy_all
  end
end
