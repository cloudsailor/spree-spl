# frozen_string_literal: true

module PaymentDecorator
  private

  def promotion_switcher(order, check_only)
    PromotionSwitcherService.new(order, check_only).call
  end

  def preform_update_sparta_state_job
    UpdateSpartaStateJob.perform_later(order.token, 'D', order.number, order.store)
  end
end
