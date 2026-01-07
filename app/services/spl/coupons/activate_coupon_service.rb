# frozen_string_literal: true

require 'json'

module Spl
  module Coupons
    class ActivateCouponService
      class ActivateCouponServiceError < StandardError; end
      include SplServiceHelper

      def initialize(user, store, coupon_code)
        @store = store
        @activate_coupons_url = URI.parse(Spl::UrlCreatorService.new(store.private_metadata['spl_url']).coupon_activate)
        @user = user
        @coupon_code = coupon_code
      end

      def call
        body = prepare_body
        response = send_request(@activate_coupons_url, body)
        response_body = JSON.parse(response.body)
        Rails.logger.debug response_body
        raise ActivateCouponServiceError, response_body['msg'] if response_body['errorCode'] != '0'

        response_body['response']
      end

      private

      def prepare_body
        {
          context: {
            prgCode: @store.private_metadata['spl_prg_code'],
            oauthToken: @user.private_metadata['spl_access_token']
          },
          couponCode: @coupon_code
        }
      end
    end
  end
end
