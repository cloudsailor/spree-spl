# frozen_string_literal: true

require 'json'

module Spl
  module Coupons
    class DeactivateCouponService
      class DeactivateCouponServiceError < StandardError; end
      include SplServiceHelper

      def initialize(user, store, params)
        @store = store
        @deactivate_coupons_url = URI.parse(Spl::UrlCreatorService.new(store.private_metadata['spl_url']).coupon_deactivate)
        @user = user
        @coupon_code = params[:coupon_code]
      end

      def call
        body = prepare_body
        response = send_request(@deactivate_coupons_url, body)
        response_body = JSON.parse(response.body)
        Rails.logger.debug response_body
        raise DeactivateCouponServiceError, response_body['msg'] if response_body['errorCode'] != '0'

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
