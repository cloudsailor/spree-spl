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
      oauth_body = prepare_token_body_with_signature
      oauth_response = send_request(@token_url, oauth_body)
      oauth_response_body = JSON.parse(oauth_response.body)
      raise SplRegisterAccountError, oauth_response_body['msg'] if oauth_response_body['errorCode'] != '0'

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

    def prepare_token_body_with_signature
      {
        apiUser: ENV['SPL_API_USER'],
        apiToken: ENV['SPL_API_TOKEN'],
        signature: generate_signature,
        date: @date,
        grantType: 'signature'
      }
    end

    def generate_signature
      data = "#{ENV["SPL_API_TOKEN"]}#{ENV["SPL_SIGNATURE_SEED"]}#{@date}"
      Rails.logger.debug data.inspect
      Digest::SHA256.hexdigest(data)
    end
  end
end
