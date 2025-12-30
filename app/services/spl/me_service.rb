# frozen_string_literal: true

require 'json'

module Spl
  class MeService < BaseSplService
    class SplMeError < StandardError; end

    def initialize(user, store)
      @me_url = URI.parse(Spl::UrlCreatorService.new(store.private_metadata['spl_url']).me)
      @user = user
      @store = store
    end

    def call
      body = prepare_me_body
      response = send_request(@me_url, body)
      response_body = JSON.parse(response.body)
      Rails.logger.debug response_body
      raise SplMeError, response_body['msg'] if response_body['errorCode'] != '0'

      response_body
    end

    private

    def prepare_me_body
      {
        context: {
          prgCode: @store.private_metadata['spl_prg_code'],
          oauthToken: @user.private_metadata['spl_access_token']
        }
      }
    end
  end
end
