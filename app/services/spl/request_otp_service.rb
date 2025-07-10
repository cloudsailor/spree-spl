# frozen_string_literal: true

require 'json'

module Spl
  class RequestOtpService
    class SplRequestOtpError < StandardError; end

    def initialize(date, params)
      @date = date.to_i * 1000
      @request_otp_url = URI.parse(Spl::UrlCreatorService.new.request_otp)
      @mobile_country = params[:mobile_country]
      @phone_number = params[:phone_number]
      @email = params[:email]
    end

    def call
      oauth_response_body = Spl::OauthTokenService.new(DateTime.current).annonymus_token
      access_token = oauth_response_body.dig('response', 'accessToken')

      request_otp_body = @email.nil? ? prepare_sms_otp_body(access_token) : prepare_email_otp_body(access_token)
      request_otp_response = send_request(@request_otp_url, request_otp_body)
      request_otp_response_body = JSON.parse(request_otp_response.body)
      Rails.logger.debug request_otp_response_body
      raise SplSendOtpCodeError, request_otp_response_body['msg'] if request_otp_response_body['errorCode'] != '0'

      request_otp_response_body
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_sms_otp_body(access_token)
      {
        context: {
          oauthToken: access_token,
          prgCode: ENV['SPL_PRG_CODE']
        },
        channel: 'S', # S = SMS
        mobileCountry: @mobile_country,
        mobile: @phone_number
      }
    end

    # below method allows sent one time password on email
    def prepare_email_otp_body(access_token)
      {
        context: {
          oauthToken: access_token,
          prgCode: ENV['SPL_PRG_CODE']
        },
        channel: 'E', # E = email
        email: @email
      }
    end

    def generate_signature
      Spl::ClientSignatureService.new(@date).call
    end
  end
end
