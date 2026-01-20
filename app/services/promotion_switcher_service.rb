# frozen_string_literal: true

class PromotionSwitcherService
  include BooleanHelper

  def initialize(order, check_only)
    @check_only = check_only
    @line_items = order.line_items
    @order = order
  end

  def call # rubocop:disable Metrics/AbcSize
    return unless order.public_metadata.key?(:spl_card_active)

    apply_sparta_discount(order, check_only) if cast_boolean(order.public_metadata[:spl_card_active])
    remove_sparta_discount(order) unless cast_boolean(order.public_metadata[:spl_card_active])
  end

  private

  attr_accessor :check_only, :line_items, :order

  def apply_sparta_discount(order, check_only)
    return unless order.line_items.any? && order.public_metadata['spl_no_card'].present?

    spl_response = Spl::SpartaLoyaltyService.new(order.token,
                                                 order.public_metadata['spl_no_card'],
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

  def remove_sparta_discount(order)
    RemoveSpartaDiscountService.destroy_all_sparta_adjustments(order)
  end
end
