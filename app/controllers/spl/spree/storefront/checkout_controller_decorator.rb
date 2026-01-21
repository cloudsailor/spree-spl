# frozen_string_literal: true

module Spl
  module Spree
    module Storefront
      module CheckoutControllerDecorator
        include BooleanHelper

        def self.prepended(base)
          base.after_action :promotion_switcher
        end

        private

        def promotion_switcher
          PromotionSwitcherService.new(@order, checkout_state_allowed?).call
        end

        def checkout_state_allowed?
          %w[cart address delivery payment].include?(request.path.split('/').last)
        end
      end
    end
  end
end
