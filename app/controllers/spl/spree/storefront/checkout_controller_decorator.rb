# frozen_string_literal: true

module Spl
  module Spree
    module Storefront
      module CheckoutControllerDecorator
        def self.prepended(base)
          base.before_action :load_user_coupons
          base.before_action :promotion_switcher
        end

        private

        def load_user_coupons
          @coupons = Spl::GetCouponsService.new(@order.user, @order.store).call
        end

        def promotion_switcher
          PromotionSwitcherService.new(@order, request.url.include?('confirm')).call
        end
      end
    end
  end
end
