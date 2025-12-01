# frozen_string_literal: true

require 'json'

module Spl
  class GetCouponsService
    class SplGetCouponError < StandardError; end

    def initialize(user)
      @get_coupons_url = URI.parse(Spl::UrlCreatorService.new.coupon_find)
      @user = user
    end

    def call
      body = prepare_me_body
      response = send_request(@get_coupons_url, body)
      response_body = JSON.parse(response.body)
      Rails.logger.debug response_body
      raise SplMeError, response_body['msg'] if response_body['errorCode'] != '0'

      response_body
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_me_body
      {
        context: {
          prgCode: ENV.fetch('SPL_PRG_CODE'),
          oauthToken: @user.private_metadata['spl_access_token']
        }
      }
    end
  end
end
