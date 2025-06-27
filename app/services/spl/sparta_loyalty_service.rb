# frozen_string_literal: true

require 'digest'
require 'net/http'
require 'json'

module Spl
  class SpartaLoyaltyService
    class SplSendRequestError < StandardError; end

    def initialize(order_token, card_number, line_items, date, products, check_only)
      @order_token = order_token
      @card_number = card_number
      @line_items = line_items
      @date = date.to_i * 1000
      @products = products
      @check_only = check_only
      @url = URI.parse(ENV['SPL_SALE_URL'])
    end

    def call
      Rails.logger.debug 'SPL LOYALTY SERVICE START'
      response = send_request
      return unless response.is_a?(Net::HTTPSuccess)

      response_body = JSON.parse(response.body)
      Rails.logger.debug 'SPL LOYALTY SERVICE RESPONSE'
      Rails.logger.debug response.body.inspect
      raise SplSendRequestError, response_body unless response_body.present? && response_body['errorCode'] == '0'

      response_body
    end

    private

    def send_request
      http = Net::HTTP.new(@url.host, @url.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(@url)
      request['Content-Type'] = 'application/json'
      request.body = prepare_basket_body.to_json
      Rails.logger.debug 'SPL LOYALTY SERVICE REQUEST BODY'
      Rails.logger.debug request.body.inspect
      http.request(request)
    end

    def prepare_basket_body # rubocop:disable Metrics/MethodLength
      {
        ver: 4,
        apiUser: ENV['SPL_API_USER'],
        apiToken: ENV['SPL_API_TOKEN'],
        partnerCode: ENV['SPL_PARTNER_CODE'],
        placeCode: ENV['SPL_PLACE_CODE'],
        mode: ENV['SPL_MODE'],
        date: @date,
        no: @order_token,
        orderNo: @order_token,
        reverse: false,
        pending: true,
        checkOnly: @check_only,
        cardNo: @card_number,
        basket: prepare_basket,
        signature: generate_signature
      }
    end

    def prepare_basket
      @line_items.map do |item|
        not_promoted = product_not_promoted?(item['variant_id'])

        {
          pos: item.id,
          quantity: item.quantity,
          productCode: item.sku,
          amountGross: item.price.to_f,
          notPromoted: not_promoted
        }
      end
    end

    def product_not_promoted?(variant_id)
      @products.any? do |product|
        (product.variants.presence || [product.default_variant]).any? do |var|
          var.id == variant_id && var.price != var.compare_at_price && var.compare_at_price.to_i.positive?
        end
      end
    end

    def generate_signature
      check_only = @check_only ? 1 : ''
      data = "#{ENV['SPL_PARTNER_CODE']}#{ENV['SPL_PLACE_CODE']}#{@date}#{@order_token}#{check_only}#{@card_number}"
      Rails.logger.debug data.inspect
      signature_base = Digest::SHA256.hexdigest(data)
      Digest::SHA256.hexdigest(signature_base + ENV['SPL_POS_KEY'])
    end
  end
end
