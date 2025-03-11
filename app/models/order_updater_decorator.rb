# frozen_string_literal: true

module OrderUpdaterDecorator
  def update
    super

    case order.payment_state
    when 'paid'
      Spl::UpdateSpartaStateService.new(order.token, 'D', order.number).call
    when 'cancelled'
      Spl::UpdateSpartaStateService.new(order.token, 'C', order.number).call
    end
  end
end
