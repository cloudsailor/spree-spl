# frozen_string_literal: true

module Spl
  module Spree
    module Storefront
      module CheckoutControllerDecorator
        def self.prepended(base)
          base.before_action :promotion_switcher
        end

        private

        def promotion_switcher
          PromotionSwitcherService.new(@order, request.url.include?('confirm')).call
        end
      end
    end
  end
end
