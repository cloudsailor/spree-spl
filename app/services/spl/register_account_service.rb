# frozen_string_literal: true

require 'json'

module Spl
  class RegisterAccountService
    class SplRegisterAccountError < StandardError; end

    def initialize(user, params)
      @register_url = URI.parse("#{ENV['SPL_URL']}/api/cwp/customer/register")
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

      spl_card = register_response_body.dig('response', 'cardNo')
      update_account(spl_card, @params)
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_registration_body(access_token) # rubocop:disable Metrics/MethodLength
      {
        context: {
          oauthToken: access_token,
          prgCode: ENV['SPL_PRG_CODE']
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

    def update_account(card_number, params)
      mobile_country = params.dig('user', 'public_metadata', 'mobileCountry')
      mobile_phone = params.dig('user', 'public_metadata', 'phone_number')
      @user.update(public_metadata: @user.public_metadata.merge('spl_no_card': card_number,
                                                                'spl_card_active': true,
                                                                'mobile_country': mobile_country,
                                                                'phone_number': mobile_phone))
    end
  end
end
