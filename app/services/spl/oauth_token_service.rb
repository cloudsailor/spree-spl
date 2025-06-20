# frozen_string_literal: true

require 'json'

module Spl
  class OauthTokenService
    class OauthTokenError < StandardError; end

    def initialize(date)
      @date = date.to_i * 1000
      @token_url = URI.parse("#{ENV['SPL_URL']}/api/oauth/token")
    end

    def call
      oauth_body = prepare_oauth_token_body_with_signature
      oauth_response = send_request(@token_url, oauth_body)
      oauth_response_body = JSON.parse(oauth_response.body)

      raise OauthTokenError, oauth_response_body['msg'] if oauth_response_body['errorCode'] != '0'

      oauth_response_body
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_oauth_token_body_with_signature
      {
        context: {
          prgCode: ENV['SPL_PRG_CODE']
        },
        apiUser: ENV['SPL_API_USER'],
        apiToken: ENV['SPL_API_TOKEN'],
        signature: generate_signature,
        date: @date,
        grantType: 'signature'
      }
    end

    def generate_signature
      Spl::ClientSignatureService.new(@date).call
    end
  end
end
