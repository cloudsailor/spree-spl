# frozen_string_literal: true

require 'digest'
require 'net/http'
require 'json'

module Spl
  class RegisterAccountService
    class SplRegisterAccountError < StandardError; end

    def initialize(date, mobile_country, phone_number)
      @date = date.to_i * 1000
      @token_url = URI.parse(ENV['SPL_CLIENT_OAUTH_TOKEN'])
      @request_otp_url = URI.parse(ENV['SPL_CLIENT_REQUEST_OTP'])
      @mobile_country = mobile_country
      @phone_number = phone_number
    end

    def call
      oauth_response_body = Spl::OauthTokenService.new(DateTime.current).call
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

    def generate_signature
      Spl::ClientSignatureService.new(@date).call
    end
  end
end
