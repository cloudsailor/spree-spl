# frozen_string_literal: true

require 'json'

module Spl
  class SendOtpService
    class SplSendOtpError < StandardError; end
    include SplServiceHelper

    def initialize(date, mobile_country, phone_number, store)
      @date = date.to_i * 1000
      @send_otp_url = URI.parse(Spl::UrlCreatorService.new(store.private_metadata['spl_url']).send_otp)
      @mobile_country = mobile_country
      @phone_number = phone_number
      @store = store
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

    def prepare_sms_otp_body # rubocop:disable Metrics/MethodLength
      {
        context: {
          prgCode: @store.private_metadata['spl_prg_code']
        },
        apiUser: @store.private_metadata['spl_api_user'],
        apiToken: @store.private_metadata['spl_api_token'],
        signatureSeed: @store.private_metadata['spl_signature_seed'],
        date: @date,
        mobileCountry: @mobile_country,
        mobile: @phone_number,
        signature: generate_signature
      }
    end

    def generate_signature
      Spl::ClientSignatureService.new(@date,
                                      @store.private_metadata['spl_api_token'],
                                      @store.private_metadata['spl_signature_seed']).call
    end
  end
end
