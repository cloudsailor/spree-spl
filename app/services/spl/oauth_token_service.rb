# frozen_string_literal: true

require 'json'

module Spl
  class OauthTokenService
    class OauthTokenError < StandardError; end

    def initialize(date)
      @date = date.to_i * 1000
      @token_url = URI.parse(Spl::UrlCreatorService.new.oauth_token)
    end

    def annonymus_token
      body = prepare_oauth_token_body_with_signature
      response = send_request(@token_url, body)
      response_body = JSON.parse(response.body)

      raise OauthTokenError, response_body['msg'] if response_body['errorCode'] != '0'

      response_body
    end

    def authorization_code_token(auth_code)
      body = prepare_oauth_token_body_with_oauth_code(auth_code)
      response = send_request(@token_url, body)
      response_body = JSON.parse(response.body)

      raise OauthTokenError, response_body['msg'] if response_body['errorCode'] != '0'

      response_body['response']
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_oauth_token_body_with_signature
      {
        context: {
          prgCode: ENV.fetch('SPL_PRG_CODE')
        },
        apiUser: ENV.fetch('SPL_API_USER'),
        apiToken: ENV.fetch('SPL_API_TOKEN'),
        signature: generate_signature,
        date: @date,
        grantType: 'signature'
      }
    end

    def prepare_oauth_token_body_with_oauth_code(auth_code)
      {
        context: {
          prgCode: ENV.fetch('SPL_PRG_CODE')
        },
        apiUser: ENV.fetch('SPL_API_USER'),
        apiToken: ENV.fetch('SPL_API_TOKEN'),
        oauthCode: auth_code,
        grantType: 'authorization_code'
      }
    end

    def generate_signature
      Spl::ClientSignatureService.new(@date).call
    end
  end
end
