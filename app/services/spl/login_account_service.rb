# frozen_string_literal: true

require 'json'

module Spl
  class LoginAccountService
    class SplLoginAccountError < StandardError; end

    def initialize(date, user, params)
      @date = date.to_i * 1000
      @login_url = URI.parse(Spl::UrlCreatorService.new.login)
      @user = user
      @mobile_country = params.dig('user', 'public_metadata', 'mobile_country')
      @phone_number = params.dig('user', 'public_metadata', 'phone_number')
      @card_number = params.dig('user', 'public_metadata', 'card_number')
      @otp_code = params.dig('user', 'public_metadata', 'spl_auth_code')
    end

    def call
      login_body = prepare_login_body
      login_response = send_request(@login_url, login_body)
      login_response_body = JSON.parse(login_response.body)
      Rails.logger.debug login_response_body
      raise SplLoginAccountError, login_response_body['msg'] if login_response_body['errorCode'] != '0'

      access_token = login_response_body.dig('response', 'oauthCode')
      get_access_token(access_token)
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_login_body # rubocop:disable Metrics/MethodLength
      {
        context: {
          prgCode: ENV.fetch('SPL_PRG_CODE')
        },
        apiUser: ENV.fetch('SPL_API_USER'),
        scope: ['spl_cwp'],
        responseType: 'code',
        login: generate_login,
        password: encrypted_otp,
        method: 'OTP'
      }
    end

    def encrypted_otp
      @otp_code.length == 6 ? Digest::SHA256.hexdigest(@otp_code) : @otp_code
    end

    def generate_login
      login = "#{@mobile_country}#{@phone_number}" if @card_number.nil?
      login = @card_number if @mobile_country.nil? || @phone_number.nil?

      login
    end

    def get_access_token(access_token)
      token_body = Spl::OauthTokenService.new(DateTime.current).authorization_code_token(access_token)
      add_loyalty_tokents_to_user(token_body['accessToken'], token_body['refreshToken'])
    end

    def add_loyalty_tokents_to_user(access_token, refresh_token)
      @user.update!(private_metadata: { spl_access_token: access_token,
                                        spl_refresh_token: refresh_token })
    end
  end
end
