# frozen_string_literal: true

module Spl
  module Spree
    module Storefront
      module CheckoutControllerDecorator
        def self.prepended(base)
          base.before_action :load_user_coupons
        end

        def activate_coupon
          debugger
          Spl::Coupons::ActivateCouponService.new(current_user, current_store, params).call

          respond_to do |format|
            format.turbo_stream
            format.html { redirect_back fallback_location: checkout_path, notice: "Coupon activated" }
          end
        end

        def deactivate_coupon; end

        private

        def load_user_coupons
          @coupons = Spl::GetCouponsService.new(@order.user, @order.store).call&.filter do |coupon|
            active?(coupon)
          end
        end

        def active?(coupon)
          coupon['used'] != true && coupon['usageTemporaryBlocked'] != true && Time.new(coupon['expirationDate']).future?
        end
      end
    end
  end
end
