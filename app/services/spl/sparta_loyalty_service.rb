# frozen_string_literal: true

require "digest"
require "net/http"
require "json"

module Spl
  class SpartaLoyaltyService
    def self.send_request(order_token, card_number, line_items, date, products, check_only) # rubocop:disable Metrics/ParameterLists
      url = URI.parse(ENV["SPL_SALE_URL"])
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request["Content-Type"] = "application/json"

      request.body = prepare_basket_body(order_token, card_number, line_items, date, products, check_only).to_json

      response = http.request(request)
      response_body = JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

      if response_body.present? && response_body["errorCode"] == "0"
        Rails.logger.debug response.body.inspect
        response_body
      else
        Rails.logger.debug response.body.inspect
        nil
      end
    end

    def self.prepare_basket_body(order_token, card_number, line_items, date, products, check_only) # rubocop:disable Metrics/ParameterLists
      date_in_ms = date.to_i * 1000
      signature = if check_only
                    signature(order_token, date_in_ms, card_number, 1)
                  else
                    signature(order_token, date_in_ms, card_number)
                  end

      {
        ver: 4,
        apiUser: ENV["SPL_API_USER"],
        apiToken: ENV["SPL_API_TOKEN"],
        partnerCode: ENV["SPL_PARTNER_CODE"],
        placeCode: ENV["SPL_PLACE_CODE"],
        mode: ENV["SPL_MODE"],
        date: date_in_ms,
        no: order_token,
        orderNo: order_token,
        reverse: false,
        pending: true,
        checkOnly: check_only,
        cardNo: card_number,
        basket: prepare_basket(line_items, products),
        signature: signature
        # debugSignatureExplain: true #param for debugging signature problems
      }
    end

    def self.prepare_basket(line_items, products)
      basket = line_items.map do |item|
        not_promoted = false
        products.each do |product|
          if product.variants.empty?
            product.variants.each do |var|
              if (var.id == item["variant_id"]) && (var.price != var.compare_at_price) && var.compare_at_price.to_i.positive? # rubocop:disable Layout/LineLength
                not_promoted = true
              end
            end
          else
            var = product.default_variant
            if (var.id == item["variant_id"]) && (var.price != var.compare_at_price) && var.compare_at_price.to_i.positive? # rubocop:disable Layout/LineLength
              not_promoted = true
            end
          end
        end

        {
          pos: item.id,
          quantity: item.quantity,
          productCode: item.sku,
          amountGross: item.price.to_f,
          notPromoted: not_promoted
        }
      end
      Rails.logger.debug basket.inspect

      basket
    end

    def self.signature(order_token, date, card_number = "", check_only = "")
      # data= "SHOPECOMM1388574855000123456719004762922649"
      data = "#{ENV["SPL_PARTNER_CODE"]}#{ENV["SPL_PLACE_CODE"]}#{date}#{order_token}#{check_only}#{card_number}"
      Rails.logger.debug data.inspect
      signature_base = Digest::SHA256.hexdigest(data)
      Digest::SHA256.hexdigest(signature_base + ENV["SPL_POS_KEY"])
    end
  end
end
