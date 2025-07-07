# frozen_string_literal: true

module Spl
  class UrlCreatorService
    def check_card
      "#{eshop_base}/checkCard"
    end

    def find
      "#{eshop_base}/find"
    end

    def sale
      "#{eshop_base}/sale"
    end

    def sale_refund
      "#{eshop_base}/saleRefund"
    end

    def register
      "#{client_base}/register"
    end

    def request_otp
      "#{client_base}/requestOTP"
    end

    def get_otp # rubocop:disable Naming/AccessorMethodName
      "#{oauth_base}/getOTP"
    end

    def login
      "#{oauth_base}/login"
    end

    def oauth_token
      "#{oauth_base}/token"
    end

    private

    def client_base
      "#{ENV.fetch('SPL_URL')}/api/cwp/customer"
    end

    def eshop_base
      "#{ENV.fetch('SPL_URL')}/api/tx"
    end

    def oauth_base
      "#{ENV.fetch('SPL_URL')}/api/oauth"
    end
  end
end
