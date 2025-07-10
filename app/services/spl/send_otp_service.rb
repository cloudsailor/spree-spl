# frozen_string_literal: true

require 'json'

module Spl
  class SendOtpService
    class SplSendOtpError < StandardError; end

    def initialize(date, mobile_country, phone_number)
      @date = date.to_i * 1000
      @send_otp_url = URI.parse(Spl::UrlCreatorService.new.send_otp)
      @mobile_country = mobile_country
      @phone_number = phone_number
    end

    def call
      send_otp_body = prepare_sms_otp_body
      send_otp_response = send_request(@send_otp_url, send_otp_body)
      send_otp_response_body = JSON.parse(send_otp_response.body)
      Rails.logger.debug send_otp_response_body
      raise SplSendOtpError, send_otp_response_body if send_otp_response_body['errorCode'] != '0'

      send_otp_response_body
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_sms_otp_body # rubocop:disable Metrics/MethodLength
      {
        context: {
          prgCode: ENV.fetch('SPL_PRG_CODE')
        },
        apiUser: ENV.fetch('SPL_API_USER'),
        apiToken: ENV.fetch('SPL_API_TOKEN'),
        signatureSeed: ENV.fetch('SPL_SIGNATURE_SEED'),
        date: @date,
        mobileCountry: @mobile_country,
        mobile: @phone_number,
        signature: generate_signature
      }
    end

    def generate_signature
      Spl::ClientSignatureService.new(@date).call
    end
  end
end
