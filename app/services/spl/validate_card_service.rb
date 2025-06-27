# frozen_string_literal: true

require 'digest'
require 'net/http'
require 'json'

module Spl
  # Validates SPL card number
  class ValidateCardService
    class SplCardValidationError < StandardError; end

    def initialize(card_number, user)
      @card_number = card_number
      @user = user
    end

    def call
      @user.public_metadata['spl_card_active'] = false

      response_body = JSON.parse(verify_card_request)
      check_for_errors(response_body)
      true
    rescue StandardError
      @user.save
      raise
    end

    private

    def check_for_errors(response_body)
      raise SplCardValidationError, response_body['msg'] if response_body['errorCode'] != '0'

      card_assignment = cards_assigned_user(@card_number)

      if card_assigned_to_different_user(card_assignment)
        raise SplCardValidationError, I18n.t('spl.card_validation.errors.wrong_owner')
      end
      raise SplCardValidationError, I18n.t('spl.card_validation.errors.card_not_match') if user_have_different_card
      raise SplCardValidationError, I18n.t('spl.card_validation.errors.card_not_active') if response_body
                                                                                            .dig('response',
                                                                                                 'card',
                                                                                                 'status') != 'A'
    end

    def verify_card_request
      url = URI.parse(ENV['SPL_CHECK_CARD_URL'])
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request['Content-Type'] = 'application/json'

      request.body = body(@card_number, DateTime.current).to_json

      response = http.request(request)
      response.body
    end

    def body(card_number, date) # rubocop: disable Metrics/MethodLength
      date_in_ms = date.to_i * 1000
      uuid = SecureRandom.uuid
      {
        ver: 4,
        requestId: uuid,
        apiUser: ENV['SPL_API_USER'],
        apiToken: ENV['SPL_API_TOKEN'],
        partnerCode: ENV['SPL_PARTNER_CODE'],
        placeCode: ENV['SPL_PLACE_CODE'],
        date: date_in_ms,
        cardNo: card_number,
        signature: signature(date_in_ms, card_number),
        extendedPersonalInfo: true
      }
    end

    def signature(date, card_number)
      data = "#{ENV['SPL_PARTNER_CODE']}#{ENV['SPL_PLACE_CODE']}#{date}#{card_number}"
      Rails.logger.debug data.inspect
      signature_base = Digest::SHA256.hexdigest(data)
      Digest::SHA256.hexdigest(signature_base + ENV['SPL_POS_KEY'])
    end

    def cards_assigned_user(card_number)
      Spree::User.find { |u| u.public_metadata['spl_no_card'] == card_number }
    end

    def card_assigned_to_different_user(card_assignment)
      card_assignment && card_assignment.id != @user.id
    end

    def user_have_different_card
      @user.public_metadata['spl_no_card'] && @user.public_metadata['spl_no_card'] != @card_number
    end
  end
end
