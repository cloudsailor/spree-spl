# frozen_string_literal: true

module Spl
  module Spree
    module Storefront
      module CheckoutControllerDecorator
        def self.prepended(base)
          base.before_action :promotion_switcher
          base.before_action :load_user_coupons, except: %i[activate_coupon deactivate_coupon]
        end

        def activate_coupon
          Spl::Coupons::ActivateCouponService
            .new(current_user, current_store, params)
            .call

          load_user_coupons

          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to checkout_path }
          end
        end

        def deactivate_coupon
          Spl::Coupons::DeactivateCouponService
            .new(current_user, current_store, params)
            .call

          load_user_coupons

          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to checkout_path }
          end
        end

        private

        def promotion_switcher
          PromotionSwitcherService.new(@order, request.url.include?('confirm')).call
        end

        def load_user_coupons
          @coupons = Spl::GetCouponsService.new(@order.user, @order.store).call&.filter do |coupon|
            active?(coupon)
          end
        end

        def active?(coupon)
          if coupon['used'] != true && coupon['usageTemporaryBlocked'] != true && coupon['expirationDate'].nil?
            return true
          end

          Time.zone.local(coupon['expirationDate']).future?
        rescue StandardError
          false
        end
      end
    end
  end
end
