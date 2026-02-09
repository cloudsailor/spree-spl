# frozen_string_literal: true

module Spl
  module Spree
    module Api
      module CheckoutControllerDecorator
        private

        def promotions_and_spl_adjustment_present?(order)
          order.promotions.any? && order.line_items.map { |li| li.adjustments.select { |a| a.preferred_external_source_type == 'SPL' } }.present?
        end

        def promotion_switcher(order, check_only)
          PromotionSwitcherService.new(order, check_only).call
        end
      end
    end
  end
end
