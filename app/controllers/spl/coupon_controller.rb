module Spl
  class CouponController < Spree::Api::V2::BaseController
    before_action do
      spree_authorize! :update, spree_current_user
    end

    def activate_coupon;end

    def deactivate_coupon; end

    private


  end
end