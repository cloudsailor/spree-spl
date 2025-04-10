# frozen_string_literal: true

class ApplySpartaDiscountService
  def initialize(response, order)
    @basket = response['response']['basket']
    @line_items = order.line_items
    @order = order
    @response = response
  end

  def call # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity
    return unless response_valid?

    line_items.each do |line_item|
      sparta_item = basket.find { |i| i['pos'] == line_item['id'] }
      spl_adjustment_present_and_spl_discounts_nil?(sparta_item, line_item)
      next if sparta_item['discounts'].nil?

      label = "SPARTA_#{sparta_item&.fetch("discounts")&.first&.fetch("name")}_#{line_item.id}"
      amount = -sparta_item&.fetch('discountGross') # Negative value for discount
      discounts_present?(sparta_item, line_item, label)
      create_sparta_adjustment(order, amount, label, line_item)
    end
  end

  private

  attr_accessor :basket, :line_items, :order, :response

  def response_valid?
    response['errorCode'] == '0' && response['response'].present? && response['response']['basket'].present?
  end

  def spl_adjustment_present_and_spl_discounts_nil?(sparta_item, line_item)
    if sparta_item['discounts'].nil? && line_item.adjustments.where(source_type: 'SPL').present?
      RemoveSpartaDiscountService.new(order).call
    end
  end

  def discounts_present?(sparta_item, line_item, label)
    debugger
    adjustments = line_item.adjustments.where(source_type: 'SPL')

    return if adjustments.blank? # Exit if no SPL adjustments exist

    existing_labels = adjustments.pluck(:label)
    unless existing_labels.include?(label)
      adjustments.where(eligible: true).update_all(eligible: false, state: 'close')
      line_item.reload
      ::Spree::Dependencies.cart_recalculate_service.constantize.call(order: order, line_item: line_item)
      adjustments.destroy_all
    end
  end

  def create_sparta_adjustment(order, amount, label, line_item)
    return if amount.zero? || line_item.adjustments.find_by(label: label).present?

    line_item.adjustments.new(
      source_type: 'SPL',
      adjustable: line_item,
      amount: amount,
      included: false,
      label: label,
      order: order
    ).save

    ::Spree::Dependencies.cart_recalculate_service.constantize.call(order: order, line_item: line_item)
  end
end
