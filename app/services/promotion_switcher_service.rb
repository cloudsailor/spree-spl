# frozen_string_literal: true

class PromotionSwitcherService
  include BooleanHelper

  def initialize(order, check_only)
    @check_only = check_only
    @line_items = order.line_items
    @order = order
  end

  def call
    apply_sparta_discount(order, check_only)
  ensure
    order.reload
  end

  private

  attr_accessor :check_only, :line_items, :order

  def apply_sparta_discount(order, check_only)
    return unless order.line_items.any?

    card_number = prepare_card_number_if_exist(order.public_metadata)
    spl_response = Spl::SpartaLoyaltyService.new(order.token,
                                                 card_number,
                                                 order.line_items,
                                                 DateTime.current,
                                                 order.products,
                                                 check_only,
                                                 order.store).call
    return unless spl_response

    create_sparta_adjustments(spl_response, order)
  end

  def create_sparta_adjustments(spl_response, order)
    ApplySpartaDiscountService.new(spl_response, order).call
  end

  def prepare_card_number_if_exist(metadata)
    cast_boolean(metadata[:spl_card_active]) ? metadata['spl_no_card'] : ''
  end
end
