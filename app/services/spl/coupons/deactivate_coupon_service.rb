# frozen_string_literal: true

require 'json'

module Spl
  module Coupons
    class DeactivateCouponService
      class DeactivateCouponServiceError < StandardError; end
      include SplServiceHelper
      include ErrorHandlingHelper
      include LoginCheckHelper

      def initialize(user, store, coupon_code)
        @store = store
        @deactivate_coupons_url = URI.parse(Spl::UrlCreatorService.new(store.private_metadata['spl_url']).coupon_deactivate)
        @user = user
        @coupon_code = coupon_code
        @retry_counter = 0
      end

      def call
        return unless @user.present? && @user.private_metadata.present?
        return unless logged_user?(@user)

        response = send_request(@deactivate_coupons_url, body)
        response_body = JSON.parse(response.body)
        Rails.logger.debug response_body
        raise DeactivateCouponServiceError, response_body['msg'] if response_body['errorCode'] != '0'

        response_body['response']
      rescue DeactivateCouponServiceError => e
        raise e unless token_refresh_needed(response_body, @retry_counter, @user)

        @retry_counter += 1
        retry
      end

      private

      def body
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
