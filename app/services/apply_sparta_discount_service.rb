# frozen_string_literal: true

class ApplySpartaDiscountService
  def initialize(response, order)
    @basket = response['response']['basket']
    @line_items = order.line_items
    @order = order
    @response = response
  end

  def call # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
    return unless response_valid?

    line_items.each do |line_item|
      sparta_item = basket.find { |i| i['pos'] == line_item['id'] }
      spl_adjustment_present_and_spl_discounts_nil?(sparta_item, line_item)
      next if sparta_item['discounts'].nil?

      label = "SPARTA_#{sparta_item&.fetch('discounts')&.first&.fetch('name')}_#{line_item.id}" # rubocop:disable Style/SafeNavigationChainLength
      amount = -sparta_item&.fetch('discountGross') # Negative value for discount
      discounts_present?(line_item, label)
      update_sparta_adjustment(line_item, label, amount)
      create_sparta_adjustment(order, amount, label, line_item)
    end
    RemoveSpartaDiscountService.destroy_not_spl_adjustments(order)
  end

  private

  attr_accessor :basket, :line_items, :order, :response

  def response_valid?
    response['errorCode'] == '0' && response['response'].present? && response['response']['basket'].present?
  end

  def spl_adjustment_present_and_spl_discounts_nil?(sparta_item, line_item)
    return unless sparta_item['discounts'].nil? && line_item.adjustments.where(source_type: 'SPL').present? # rubocop:disable Style/ReturnNilInPredicateMethodDefinition

    adjustments = line_item.adjustments.where(source_type: 'SPL')
    RemoveSpartaDiscountService.destroy_inactive_adjustments(adjustments, line_item, order)
  end

  def discounts_present?(line_item, label)
    adjustments = line_item.adjustments.where(source_type: 'SPL')
    return if adjustments.blank? # rubocop:disable Style/ReturnNilInPredicateMethodDefinition

    existing_labels = adjustments.pluck(:label)
    return if existing_labels.include?(label) # rubocop:disable Style/ReturnNilInPredicateMethodDefinition

    RemoveSpartaDiscountService.destroy_inactive_adjustments(adjustments, line_item, order)
  end

  def create_sparta_adjustment(order, amount, label, line_item)
    return if amount.zero? || line_item.adjustments.find_by(label: label, amount: amount).present?

    line_item.adjustments.create(
      source_type: 'SPL',
      adjustable: line_item,
      amount: amount,
      included: false,
      label: label,
      order: order
    )

    ::Spree::Dependencies.cart_recalculate_service.constantize.call(order: order, line_item: line_item)
  end

  def update_sparta_adjustment(line_item, label, amount)
    adjustments = line_item.adjustments
    return if amount.zero? || adjustments.find_by(label: label).nil?
    return if adjustments.find_by(label: label, amount: amount).present?

    remove_spree_promotions_adjustments(line_item)
    adjustments.find_by(label: label).update(amount: amount)
  end

  def remove_spree_promotions_adjustments(line_item)
    return unless line_item.adjustments.where.not(source_type: 'SPL').any?

    line_item.adjustments.where.not(source_type: 'SPL').destroy_all
  end
end
