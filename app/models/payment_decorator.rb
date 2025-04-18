# frozen_string_literal: true

module PaymentDecorator
  private

  def promotion_switcher(order, check_only)
    return unless order.public_metadata.key?(:spl_no_card) && order.public_metadata.key?(:spl_card_active)
    return unless order.public_metadata['spl_card_active']

    PromotionSwitcherService.new(order, check_only).call
  end

  def update_sparta_state
    return unless order.public_metadata.key?(:spl_no_card) && order.public_metadata.key?(:spl_card_active)
    return unless order.public_metadata['spl_card_active']

    UpdateSpartaStateJob.perform_later(order.token, 'D', order.number)
  end
end
