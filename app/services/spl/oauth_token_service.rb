# frozen_string_literal: true

require 'json'

module Spl
  class OauthTokenService
    class OauthTokenError < StandardError; end
    include SplServiceHelper

    def initialize(date, store)
      @date = date.to_i * 1000
      @env = Spl::StorePrivateMetadataService.all(store)
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

    def prepare_oauth_token_body_with_signature
      {
        context: {
          prgCode: @env['spl_prg_code']
        },
        apiUser: @env['spl_api_user'],
        apiToken: @env['spl_api_token'],
        signature: generate_signature,
        date: @date,
        grantType: 'signature'
      }
    end

    def prepare_oauth_token_body_with_oauth_code(auth_code)
      {
        context: {
          prgCode: @env['spl_prg_code']
        },
        apiUser: @env['spl_api_user'],
        apiToken: @env['spl_api_token'],
        oauthCode: auth_code,
        grantType: 'authorization_code'
      }
    end

    def generate_signature
      Spl::ClientSignatureService.new(@date,
                                      @env['spl_api_token'],
                                      @env['spl_signature_seed']).call
    end
  end
end
