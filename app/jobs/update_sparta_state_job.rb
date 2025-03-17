# frozen_string_literal: true

require "digest"
require "net/http"
require "json"

class UpdateSpartaStateJob < ActiveJob::Base # rubocop:disable Metrics/ClassLength
  def perform(order_token, state, order_number)
    return if order_token.blank? || !%w[C D].include?(state&.upcase)

    transaction = find_transaction(order_token)
    return if transaction.blank?

    Rails.logger.debug transaction.inspect

    case state
    when "D"
      update_order_status(order_token, state, transaction["basket"], DateTime.parse(transaction["date"]),
                          transaction["cardNo"], order_number)
    when "C"
      refund(order_token, state, transaction["basket"], DateTime.parse(transaction["date"]), transaction["cardNo"])
    end
  end

  private

  def update_order_status(order_token, state, basket, date, card_number, order_number = "") # rubocop:disable Metrics/ParameterLists
    url = URI.parse(ENV["SPL_SALE_URL"])
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request.body = body(order_token, state, basket, date, card_number, order_number).to_json
    Rails.logger.debug request.body

    response = http.request(request)
    response_body = JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
    return if response_body.present? && error_code_matches?(response_body)
    raise StandardError, response.body.inspect unless response_body.present? && response_body["errorCode"] == "0"

    Rails.logger.debug response_body.inspect
    response_body
  end

  def body(order_token, _state, basket, date, card_number, order_number) # rubocop:disable Metrics/ParameterLists,Metrics/MethodLength
    # state is "C" order cancelled, "D" order confirmed.
    date_in_ms = date.to_i * 1000
    {
      ver: 3,
      apiUser: ENV["SPL_API_USER"],
      apiToken: ENV["SPL_API_TOKEN"],
      partnerCode: ENV["SPL_PARTNER_CODE"],
      placeCode: ENV["SPL_PLACE_CODE"],
      mode: "STEP2_KEEP_DISCOUNTS",
      pending: false,
      date: date_in_ms,
      no: order_token,
      cardNo: card_number,
      documentNo: order_number,
      basket: basket,
      signature: signature(order_token, date_in_ms, card_number, order_number),
      debugSignatureExplain: true
    }
  end

  def find_transaction(order_token)
    url = URI.parse(ENV["SPL_ORDER_FIND_URL"])
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request.body = find_transaction_body(order_token).to_json
    Rails.logger.debug request.body

    response = http.request(request)
    response_body = JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
    return response_body["response"]&.first if response_body.present? && response_body["errorCode"] == "0"

    return nil if response_body.present? && error_code_matches?(response_body)

    raise StandardError, response.body.inspect
  end

  def error_code_matches?(response_body)
    error_codes = %w[ORDER_NOT_FOUND REQUEST_ALREADY_PROCESSED]
    error_codes.include?(response_body["errorCode"])
  end

  def find_transaction_body(order_token) # rubocop:disable Metrics/MethodLength
    date_in_ms = DateTime.current.to_i * 1000
    {
      ver: 3,
      apiUser: ENV["SPL_API_USER"],
      apiToken: ENV["SPL_API_TOKEN"],
      partnerCode: ENV["SPL_PARTNER_CODE"],
      placeCode: ENV["SPL_PLACE_CODE"],
      requestDate: date_in_ms,
      no: order_token,
      prgCode: "yescz",
      orderNo: order_token,
      signature: signature("", date_in_ms)
    }
  end

  def signature(order_number, date = "", card_number = "", check_only = "", order_name = "")
    # data= "SHOPECOMM1388574855000123456719004762922649"
    data = "#{ENV["SPL_PARTNER_CODE"]}#{ENV["SPL_PLACE_CODE"]}#{date}#{order_number}#{order_name}#{check_only}#{card_number}" # rubocop:disable Layout/LineLength
    Rails.logger.debug data.inspect
    signature_base = Digest::SHA256.hexdigest(data)
    Digest::SHA256.hexdigest(signature_base + ENV["SPL_POS_KEY"])
  end

  def refund(order_token, state, basket, date, card_number)
    url = URI.parse(ENV["SPL_REFUND_URL"])
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request.body = refund_body(order_token, state, basket, date, card_number).to_json
    Rails.logger.debug request.body

    response = http.request(request)
    response_body = JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
    raise StandardError, response.body.inspect unless response_body.present? && response_body["errorCode"] == "0"

    Rails.logger.debug response_body.inspect
    response_body
  end

  def refund_body(order_token, _state, basket, date, card_number) # rubocop:disable Metrics/MethodLength
    # state is "C" order cancelled, "D" order confirmed.
    date_in_ms = date.to_i * 1000
    new_number = SecureRandom.uuid
    {
      ver: 3,
      prgCode: "yescz",
      apiUser: ENV["SPL_API_USER"],
      apiToken: ENV["SPL_API_TOKEN"],
      mode: "NGD",
      partnerCode: ENV["SPL_PARTNER_CODE"],
      placeCode: ENV["SPL_PLACE_CODE"],
      relPartnerCode: ENV["SPL_PARTNER_CODE"],
      relPlaceCode: ENV["SPL_PLACE_CODE"],
      relDate: date_in_ms,
      relNo: order_token,
      date: date_in_ms,
      orderNo: new_number,
      no: new_number,
      cardNo: card_number,
      basket: basket,
      signature: signature(new_number, date_in_ms, card_number)
    }
  end
end
