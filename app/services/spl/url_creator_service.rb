# frozen_string_literal: true

module Spl
  class UrlCreatorService
    def initialize(url)
      @url = url
    end

    def check_card
      "#{eshop_base}/checkCard"
    ## Client data
    def me
      "#{client_base}/me"
    end

    ## Promotions data
    def find
      "#{eshop_base}/find"
    end

    def sale
      "#{eshop_base}/sale"
    end

    def sale_refund
      "#{eshop_base}/saleRefund"
    end

    ## Coupons

    def coupon_find
      "#{coupon_base}/find"
    end

    ## Authentication and Authorization

    def check_card
      "#{eshop_base}/checkCard"
    end

    def register
      "#{client_base}/register"
    end

    def request_otp
      "#{client_base}/requestOTP"
    end

    def login
      "#{oauth_base}/login"
    end

    def send_otp
      "#{oauth_base}/sendOTP"
    end

    def oauth_token
      "#{oauth_base}/token"
    end

    private

    def client_base
      "#{@url}/api/cwp/customer"
    end

    def eshop_base
      "#{@url}/api/tx"
    end

    def oauth_base
      "#{@url}/api/oauth"
    end

    def coupon_base
      "#{@url}/api/cwp/coupon"
    end
  end
end
