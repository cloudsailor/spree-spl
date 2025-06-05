# frozen_string_literal: true

require 'digest'
require 'net/http'
require 'json'

module Spl
  class RegisterAccountService
    class SplRegisterAccountError < StandardError; end

    def initialize(date, user, params)
      @date = date.to_i * 1000
      @register_url = URI.parse(ENV['SPL_CLIENT_REGISTER'])
      @user = user
      @params = params
    end

    def call
      oauth_response_body = Spl::OauthTokenService.new(DateTime.current).call
      access_token = oauth_response_body.dig('response', 'accessToken')

      register_body = prepare_registration_body(access_token)
      register_response = send_request(@register_url, register_body)
      register_response_body = JSON.parse(register_response.body)
      raise SplRegisterAccountError, register_response_body if register_response_body['errorCode'] != '0'

      register_response_body
    end

    private

    def send_request(url, body)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request['Content-Type'] = 'application/json'
      request.body = body.to_json
      Rails.logger.debug request.body.inspect
      http.request(request)
    end

    def prepare_registration_body(acccess_token) # rubocop:disable Metrics/MethodLength
      {
        context: {
          oauthToken: acccess_token
        },
        person: {
          firstName: @user[:first_name],
          lastName: @user[:first_name],
          email: @user[:email],
          pass: @user[:encrypted_password],
          mobileCountry: @params.dig('user', 'public_metadata', 'mobileCountry'),
          mobile: @params.dig('user', 'public_metadata', 'phone_number'),
          permissions: {
            processData: @params.dig('user', 'public_metadata', 'splProcessData'),
            operationalSms: @params.dig('user', 'public_metadata', 'operationalSms')
          }
        },
        authCode: @params.dig('user', 'public_metadata', 'splAuthCode'),
        partnerCode: ENV['SPL_PARTNER_CODE'],
        placeCode: ENV['SPL_PLACE_CODE']
      }
    end
  end
end
