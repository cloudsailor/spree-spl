# frozen_string_literal: true

require 'json'

module Spl
  class MeService
    class SplMeError < StandardError; end

    def initialize(user)
      @me_url = URI.parse(Spl::UrlCreatorService.new.me)
      @user = user
    end

    def call
      me_body = prepare_me_body
      me_response = send_request(@me_url, me_body)
      me_response_body = JSON.parse(me_response.body)
      Rails.logger.debug me_response_body
      raise SplMeError, me_response_body['msg'] if me_response_body['errorCode'] != '0'

      me_response_body
    end

    private

    def send_request(url, body)
      Spl::SendRequestService.new(url, body).call
    end

    def prepare_me_body
      {
        context: {
          prgCode: ENV.fetch('SPL_PRG_CODE'),
          oauthToken: @user.private_metadata['spl_access_token']
        }
      }
    end
  end
end
