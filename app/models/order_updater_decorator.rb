# frozen_string_literal: true

module OrderUpdaterDecorator
  private

  def preform_update_sparta_state_job
    UpdateSpartaStateJob.perform_later(order.token, 'D', order.number) if order.payment_state == 'paid'
    UpdateSpartaStateJob.perform_later(order.token, 'C', order.number) if order.state == 'canceled'
  end

  def check_spl_adjustments # rubocop:disable Metrics/MethodLength
    if order.public_metadata['spl_card_active'] == true
      updated_any_adjustment = false
      order.adjustments.each do |adjustment|
        if adjustment.source_type != 'SPL' && adjustment.eligible?
          adjustment.update(eligible: false)
          updated_any_adjustment = true
        end
      end
      updated_any_adjustment
    else
      false
    end
  end
end
