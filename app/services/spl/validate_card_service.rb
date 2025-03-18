# frozen_string_literal: true

require "digest"
require "net/http"
require "json"

module Spl
  # Validates SPL card number
  class ValidateCardService
    class SplCardValidationError < StandardError; end

    def initialize(card_number, user)
      @card_number = card_number
      @user = user
    end

    def call # rubocop: disable Metrics/MethodLength
      response_body = JSON.parse(verify_card_request)

      raise SplCardValidationError, response_body if response_body["errorCode"] != "0"

      card_assignment = cards_assigned_user(@card_number)

      if card_assigned_to_different_user(card_assignment)
        raise SplCardValidationError,
              "Card assigned to a different user"
      end
      raise SplCardValidationError, "Card doesnt match user's card number" if user_have_different_card
      raise SplCardValidationError, "Card is not active" if response_body.dig("response", "card", "status") != "A"

      assign_card_to_user
      true
    end

    private

    def verify_card_request
      url = URI.parse(ENV["SPL_CHECK_CARD_URL"])
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"

      request.body = body(@card_number, DateTime.current).to_json

      response = http.request(request)
      response.body
    end

    def body(card_number, date) # rubocop: disable Metrics/MethodLength
      date_in_ms = date.to_i * 1000
      uuid = SecureRandom.uuid
      {
        "ver": 4,
        "requestId": uuid,
        apiUser: ENV["SPL_API_USER"],
        apiToken: ENV["SPL_API_TOKEN"],
        partnerCode: ENV["SPL_PARTNER_CODE"],
        placeCode: ENV["SPL_PLACE_CODE"],
        "date": date_in_ms,
        "cardNo": card_number, # "8006683868175"
        "signature": signature(date_in_ms, card_number),
        "extendedPersonalInfo": true
      }
    end

    def signature(date, card_number)
      data = "#{ENV["SPL_PARTNER_CODE"]}#{ENV["SPL_PLACE_CODE"]}#{date}#{card_number}"
      Rails.logger.debug data.inspect
      signature_base = Digest::SHA256.hexdigest(data)
      Digest::SHA256.hexdigest(signature_base + ENV["SPL_POS_KEY"])
    end

    def cards_assigned_user(card_number)
      Spree::User.find { |u| u.public_metadata["spl_no_card"] == card_number }
    end

    def card_assigned_to_different_user(card_assignment)
      card_assignment && card_assignment.id != @user.id
    end

    def user_have_different_card
      @user.public_metadata["spl_no_card"] && @user.public_metadata["spl_no_card"] != @card_number
    end

    def assign_card_to_user
      return if @user.public_metadata["spl_no_card"] == @card_number

      @user.update(public_metadata: @user.public_metadata.merge({ "spl_no_card" => @card_number}))
      @user.save
    end
  end
end
