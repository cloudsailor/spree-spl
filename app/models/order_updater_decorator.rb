# frozen_string_literal: true

module OrderUpdaterDecorator
  private

  def preform_update_sparta_state_job # rubocop:disable Metrics/AbcSize
    UpdateSpartaStateJob.perform_later(order.token, 'D', order.number, order.store) if order.payment_state == 'paid'
    UpdateSpartaStateJob.perform_later(order.token, 'C', order.number, order.store) if order.state == 'canceled'
  end
end
