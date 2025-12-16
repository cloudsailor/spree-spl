# frozen_string_literal: true

require 'json'

module Spl
  class SendOtpService
    class SplSendOtpError < StandardError; end

    def initialize(date, mobile_country, phone_number, store)
      @date = date.to_i * 1000
      @send_otp_url = URI.parse(Spl::UrlCreatorService.new(store.private_metadata['spl_url']).send_otp)
      @mobile_country = mobile_country
      @phone_number = phone_number
      @env = Spl::StorePrivateMetadataService.all(store)
    end

    def call
      body = prepare_sms_otp_body
      response = send_request(@send_otp_url, body)
      response_body = JSON.parse(response.body)
      Rails.logger.debug response_body
      raise SplSendOtpError, response_body['msg'] if response_body['errorCode'] != '0'

      response_body
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_sms_otp_body # rubocop:disable Metrics/MethodLength
      {
        context: {
          prgCode: @env['spl_prg_code']
        },
        apiUser: @env['spl_api_user'],
        apiToken: @env['spl_api_token'],
        signatureSeed: @env['spl_signature_seed'],
        date: @date,
        mobileCountry: @mobile_country,
        mobile: @phone_number,
        signature: generate_signature
      }
    end

    def generate_signature
      Spl::ClientSignatureService.new(@date,
                                      @env['spl_api_token'],
                                      @env['spl_signature_seed']).call
    end
  end
end
