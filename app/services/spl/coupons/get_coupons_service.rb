# frozen_string_literal: true

require 'json'

module Spl
  module Coupons
    class GetCouponsService
      class SplGetCouponError < StandardError; end
      include SplServiceHelper
      include ErrorHandlingHelper
      include LoginCheckHelper

      def initialize(user, store)
        @store = store
        @find_coupons_url = URI.parse(Spl::UrlCreatorService.new(store.private_metadata['spl_url']).coupon_find)
        @user = user
        @retry_counter = 0
      end

      def call
        return unless @user.present? && @user.private_metadata.present?
        return unless logged_user?(@user)

        response = send_request(@find_coupons_url, body)
        response_body = JSON.parse(response.body)
        Rails.logger.debug response_body
        raise SplGetCouponError, response_body['msg'] if response_body['errorCode'] != '0'

        filtered_coupons(response_body)
      rescue SplGetCouponError => e
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
          withArchival: true
        }
      end

      def filtered_coupons(response_body)
        response_body['response']&.filter do |coupon|
          active?(coupon)
        end
      end

      def active?(coupon)
        coupon['used'] != true && coupon['usageTemporaryBlocked'] != true && correct_time?(coupon['expirationDate']) &&
          coupon['usageDisabled'] != true
      end

      def correct_time?(date)
        return Time.zone.parse(date).future? unless date.nil?

        true
      end
    end
  end
end
