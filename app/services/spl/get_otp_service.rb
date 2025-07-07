# frozen_string_literal: true

require 'json'

module Spl
  class GetOtpService
    class SplGetOtpError < StandardError; end

    def initialize(date, card_number)
      @date = date.to_i * 1000
      @get_otp_url = URI.parse(Spl::UrlCreatorService.new.get_otp)
      @card_number = card_number
    end

    def call
      get_otp_body = prepare_connect_account_body
      get_otp_response = send_request(@get_otp_url, get_otp_body)
      get_otp_response_body = JSON.parse(get_otp_response.body)
      Rails.logger.debug get_otp_response_body
      raise SplGetOtpError, get_otp_response_body if get_otp_response_body['errorCode'] != '0'

      get_otp_response_body
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_connect_account_body
      {
        context: {
          prgCode: ENV.fetch('SPL_PRG_CODE')
        },
        apiUser: ENV.fetch('SPL_API_USER'),
        apiToken: ENV.fetch('SPL_API_TOKEN'),
        signature: generate_signature,
        date: @date,
        login: card_number
      }
    end

    def generate_signature
      Spl::ClientSignatureService.new(@date).call
    end
  end
end
