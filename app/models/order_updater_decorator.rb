# frozen_string_literal: true

module OrderUpdaterDecorator
  def update
    super
    debugger
    UpdateSpartaStateJob.perform_later(order.token, 'D', order.number) if order.payment_state == 'paid'
    UpdateSpartaStateJob.perform_later(order.token, 'C', order.number) if order.state == 'canceled'
  end
end
