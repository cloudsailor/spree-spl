class RemoveSpartaDiscountService
  def initialize(order)
    @line_items = order.line_items
    @order = order
  end

  def call
    line_items.each do |line_item|
      next unless line_item.adjustments.any? { |adj| adj.label&.start_with?("SPARTA") }

      remove_sparta_adjustment(line_item)
    end
  end

  private

  attr_accessor :line_items, :order

  def remove_sparta_adjustment(line_item)
    line_item.adjustments.where("label LIKE ?", "SPARTA%").where(eligible: true).destroy_all

    line_item.reload
    ::Spree::Dependencies.cart_recalculate_service.constantize.call(order: order, line_item: line_item)
  end
end
