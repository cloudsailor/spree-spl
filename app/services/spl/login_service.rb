# frozen_string_literal: true

require 'json'

module Spl
  class LoginService
    class SplLoginError < StandardError; end

    def initialize(date, card_number)
      @date = date.to_i * 1000
      @login_url = URI.parse(Spl::UrlCreatorService.new.login)
      @card_number = card_number
    end

    def call
      get_otp_response_body = Spl::GetOtpService.new(DateTime.current, card_number).call
      otp_code = get_otp_response_body.dig('response', 'authCode')

      login_body = prepare_login_body(otp_code)
      login_response = send_request(@login_url, login_body)
      login_response_body = JSON.parse(login_response.body)
      Rails.logger.debug login_response_body
      raise SplLoginError, login_response_body if login_response_body['errorCode'] != '0'
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_login_body(otp_code)
      {
        context: {
          prgCode: ENV.fetch('SPL_PRG_CODE')
        },
        apiUser: ENV.fetch('SPL_API_USER'),
        scope: ['spl_cwp'],
        responseType: 'code',
        login: @card_number,
        password: otp_code,
        method: 'OTP'
      }
    end
  end
end
