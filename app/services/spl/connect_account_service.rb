# frozen_string_literal: true

require 'json'

module Spl
  class ConnectAccountService
    class SplConnectAccountError < StandardError; end

    def initialize(date, user, mobile_country, phone_number)
      @date = date.to_i * 1000
      @get_otp_url = URI.parse(Spl::UrlCreatorService.new.get_otp)
      @user = user
      @mobile_country = mobile_country
      @phone_number = phone_number
    end

    def call
      debugger
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_connect_account_body
      {
        context: {
          prgCode: ENV['SPL_PRG_CODE']
        },
        apiUser: ENV['SPL_API_USER'],
        apiToken: ENV['SPL_API_TOKEN'],
        signature: generate_signature,
        date: @date,
        login: "#{@mobile_country}#{@phone_number}"
      }
    end

    def generate_signature
      Spl::ClientSignatureService.new(@date).call
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
