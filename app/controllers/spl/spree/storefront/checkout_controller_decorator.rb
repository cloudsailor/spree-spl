# frozen_string_literal: true

module Spl
  module Spree
    module Storefront
      module CheckoutControllerDecorator
        include ErrorHandlingHelper

        def self.prepended(base)
          base.before_action :promotion_switcher
          base.before_action :load_user_coupons, except: %i[activate_coupon deactivate_coupon]
        end

        def activate_coupon
          Spl::Coupons::ActivateCouponService.new(@order.user, @order.store, params[:coupon_code]).call
          load_user_coupons
        rescue StandardError => e
          handle_spl_error(e)
          raise e
        ensure
          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to checkout_path }
          end
        end

        def deactivate_coupon
          Spl::Coupons::DeactivateCouponService
            .new(@order.user, @order.store, params[:coupon_code])
            .call
          load_user_coupons
        rescue StandardError => e
          handle_spl_error(e)
          raise e
        ensure
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
          @coupons = Spl::Coupons::GetCouponsService.new(@order.user, @order.store).call
        rescue StandardError
          handle_spl_error(e)
          raise e
        end
      end
    end
  end
end
