# frozen_string_literal: true

require 'json'

module Spl
  class OauthTokenService
    class OauthTokenError < StandardError; end

    def initialize(date, store)
      @date = date.to_i * 1000
      @store = store
      @token_url = URI.parse(Spl::UrlCreatorService.new(store.private_metadata['spl_url']).oauth_token)
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
          prgCode: @store.private_metadata['spl_prg_code']
        },
        apiUser: @store.private_metadata['spl_api_user'],
        apiToken: @store.private_metadata['spl_api_token'],
        signature: generate_signature,
        date: @date,
        grantType: 'signature'
      }
    end

    def prepare_oauth_token_body_with_oauth_code(auth_code)
      {
        context: {
          prgCode: @store.private_metadata['spl_prg_code']
        },
        apiUser: @store.private_metadata['spl_api_user'],
        apiToken: @store.private_metadata['spl_api_token'],
        oauthCode: auth_code,
        grantType: 'authorization_code'
      }
    end

    def generate_signature
      Spl::ClientSignatureService.new(@date, @store.private_metadata['spl_api_token'], @store.private_metadata['spl_signature_seed']).call
    end
  end
end
