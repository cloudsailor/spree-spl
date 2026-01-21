# frozen_string_literal: true

module Spl
  module Spree
    module Storefront
      module CheckoutControllerDecorator
        include BooleanHelper

        def self.prepended(base)
          base.before_action :promotion_switcher
          base.after_action :perform_update_sparta_state_job, only: %i[confirm complete]
        end

        private

        def promotion_switcher
          PromotionSwitcherService.new(@order, checkout_state_allowed?).call
        end

        def checkout_state_allowed?
          %w[cart address delivery payment].include?(request.path.split('/').last)
        end

        def perform_update_sparta_state_job
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
