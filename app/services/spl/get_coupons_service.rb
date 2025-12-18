# frozen_string_literal: true

require 'json'

module Spl
  class GetCouponsService
    class SplGetCouponError < StandardError; end

    def initialize(user, store)
      @store = store
      @find_coupons_url = URI.parse(Spl::UrlCreatorService.new(store.private_metadata['spl_url']).coupon_find)
      @user = user
    end

    def call
      body = prepare_body
      response = send_request(@find_coupons_url, body)
      response_body = JSON.parse(response.body)
      Rails.logger.debug response_body
      raise SplGetCouponError, response_body['msg'] if response_body['errorCode'] != '0'

      response_body['response']
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_body
      {
        context: {
          prgCode: @store.private_metadata['spl_prg_code'],
          oauthToken: @user.private_metadata['spl_access_token']
        }
      }
    end
  end
end
