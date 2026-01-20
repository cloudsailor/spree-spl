# frozen_string_literal: true

module Spl
  module Spree
    module Admin
      module PaymentsControllerDecorator
        def self.prepended(base)
          base.after_action :preform_update_sparta_state_job, only: :capture
        end

        private

        def preform_update_sparta_state_job
          if @order.payment_state == 'paid'
            UpdateSpartaStateJob.perform_later(@order.token, 'D', @order.number, @order.store)
          end
          if @order.state == 'canceled'
            UpdateSpartaStateJob.perform_later(@order.token, 'C', @order.number, @order.store)
          end
        end
      end
    end
  end
end
