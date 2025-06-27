# frozen_string_literal: true

require 'digest'
require 'net/http'
require 'json'

class UpdateSpartaStateJob < ActiveJob::Base
  ORDER_STATES = %w[C D].freeze
  ERROR_CODES = %w[ORDER_NOT_FOUND REQUEST_ALREADY_PROCESSED].freeze

  def perform(order_token, state, order_number)
    return if order_token.blank? || !ORDER_STATES.include?(state&.upcase)

    transaction = find_transaction(order_token)
    return if transaction.blank?

    Rails.logger.debug transaction.inspect

    date = DateTime.parse(transaction['date'])
    card_number = transaction['cardNo']
    basket = transaction['basket']

    case state
    when 'D'
      update_order_status(order_token, basket, date, card_number, order_number)
    when 'C'
      refund(order_token, basket, date, card_number)
    end
  end

  private

  def send_request(url, body)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/json'
    request.body = body.to_json
    Rails.logger.debug request.body

    response = http.request(request)
    JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
  end

  def update_order_status(order_token, basket, date, card_number, order_number = '')
    body = build_body(order_token, basket, date, card_number, order_number)
    sale_url = URI.parse(Spl::UrlCreatorService.new.sale)
    response_body = send_request(sale_url, body)
    handle_response(response_body)
  end

  def find_transaction(order_token)
    body = build_find_transaction_body(order_token)
    order_find_url = URI.parse(Spl::UrlCreatorService.new.find)
    response_body = send_request(order_find_url, body)
    response_body&.dig('response', 0) if response_body && response_body['errorCode'] == '0'
  end

  def refund(order_token, basket, date, card_number)
    body = build_refund_body(order_token, basket, date, card_number)
    refund_url = URI.parse(Spl::UrlCreatorService.new.sale_refund)
    response_body = send_request(refund_url, body)
    handle_response(response_body)
  end

  def build_body(order_token, basket, date, card_number, order_number)
    date_in_ms = date.to_i * 1000
    {
      ver: 4,
      apiUser: ENV['SPL_API_USER'],
      apiToken: ENV['SPL_API_TOKEN'],
      partnerCode: ENV['SPL_PARTNER_CODE'],
      placeCode: ENV['SPL_PLACE_CODE'],
      mode: ENV['SPL_UPDATE_STATUS_MODE'],
      pending: false,
      date: date_in_ms,
      no: order_token,
      cardNo: card_number,
      documentNo: order_number,
      basket: basket,
      signature: generate_signature(order_token, date_in_ms, card_number, order_number)
    }
  end

  def build_find_transaction_body(order_token)
    date_in_ms = DateTime.current.to_i * 1000
    {
      ver: 3,
      apiUser: ENV['SPL_API_USER'],
      apiToken: ENV['SPL_API_TOKEN'],
      partnerCode: ENV['SPL_PARTNER_CODE'],
      placeCode: ENV['SPL_PLACE_CODE'],
      requestDate: date_in_ms,
      no: order_token,
      prgCode: ENV['SPL_PRG_CODE'],
      orderNo: order_token,
      signature: generate_signature('', date_in_ms)
    }
  end

  def build_refund_body(order_token, basket, date, card_number)
    date_in_ms = date.to_i * 1000
    new_number = SecureRandom.uuid
    {
      ver: 3,
      prgCode: ENV['SPL_PRG_CODE'],
      apiUser: ENV['SPL_API_USER'],
      apiToken: ENV['SPL_API_TOKEN'],
      mode: ENV['SPL_MODE'],
      partnerCode: ENV['SPL_PARTNER_CODE'],
      placeCode: ENV['SPL_PLACE_CODE'],
      relPartnerCode: ENV['SPL_PARTNER_CODE'],
      relPlaceCode: ENV['SPL_PLACE_CODE'],
      relDate: date_in_ms,
      relNo: order_token,
      date: date_in_ms,
      orderNo: new_number,
      no: new_number,
      cardNo: card_number,
      basket: basket,
      signature: generate_signature(new_number, date_in_ms, card_number)
    }
  end

  def generate_signature(order_number, date = '', card_number = '', check_only = '', order_name = '') # rubocop:disable Metrics/ParameterLists
    data = "#{ENV['SPL_PARTNER_CODE']}#{ENV['SPL_PLACE_CODE']}#{date}#{order_number}#{order_name}#{check_only}#{card_number}" # rubocop:disable Layout/LineLength
    Rails.logger.debug data.inspect
    signature_base = Digest::SHA256.hexdigest(data)
    Digest::SHA256.hexdigest(signature_base + ENV['SPL_POS_KEY'])
  end

  def handle_response(response_body)
    return if response_body.present? && ERROR_CODES.include?(response_body['errorCode'])
    raise StandardError, response_body.inspect unless response_body.present? && response_body['errorCode'] == '0'

    Rails.logger.debug response_body.inspect
  end
end
