# frozen_string_literal: true

class PromotionSwitcherService
  def initialize(order, user, check_only)
    @check_only = check_only
    @line_items = order.line_items
    @order = order
    @user = user
  end

  def call # rubocop:disable Metrics/AbcSize
    return unless order.public_metadata.key?(:spl_card_active)

    apply_sparta_discount(order, user, check_only) if order.public_metadata[:spl_card_active]
    remove_sparta_discount(order) unless order.public_metadata[:spl_card_active]
  ensure
    order.reload
  end

  private

  attr_accessor :check_only, :line_items, :order, :user

  def apply_sparta_discount(order, user, check_only) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return unless order.line_items.any? && order.public_metadata['spl_no_card'].present?

    spl_response = Spl::SpartaLoyaltyService.new(order.token,
                                                 order.public_metadata['spl_no_card'],
                                                 order.line_items,
                                                 DateTime.current,
                                                 order.products,
                                                 check_only).call
    return unless spl_response

    create_sparta_adjustments(spl_response, order)
    Rails.logger.debug spl_response
  end

  def create_sparta_adjustments(spl_response, order)
    ApplySpartaDiscountService.new(spl_response, order).call
  end

  def remove_sparta_discount(order)
    RemoveSpartaDiscountService.new(order).call
  end
end
