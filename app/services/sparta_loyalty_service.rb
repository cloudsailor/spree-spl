require "digest"
require "net/http"
require "json"

class SpartaLoyaltyService
  def self.send_request(order_number, card_number, line_items, date, products, check_only = true)
    url = URI.parse(ENV["SPL_SALE_URL"])
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["Content-Type"] = "application/json"
    request.body = prepare_request_body(order_number, card_number, line_items, date, products, check_only)

    response = http.request(request)
    response_body = JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

    if response_body.present? && response_body["errorCode"] == "0"
      puts response.body.inspect
      return response_body
    else
      puts response.body.inspect
      return nil
    end
  end

  private

  def self.prepare_request_body(order_number, card_number, line_items, date, products, check_only)
    if check_only
      prepare_check_basket_body(order_number, card_number, line_items, date, products).to_json
    else
      prepare_basket_body(order_number, card_number, line_items, date, products).to_json
    end
  end

  def self.prepare_check_basket_body(order_number, card_number, line_items, date, products)
    date_in_ms = date.to_i * 1000
    {
      ver: 4,
      apiUser: ENV["SPL_API_USER"],
      apiToken: ENV["SPL_API_TOKEN"],
      partnerCode: ENV["SPL_PARTNER_CODE"],
      placeCode: ENV["SPL_PLACE_CODE"],
      mode: ENV["SPL_MODE"],
      date: date_in_ms,
      no: order_number,
      orderNo: order_number,
      reverse: false,
      pending: true,
      checkOnly: true,
      cardNo: card_number,
      basket: prepare_basket(line_items, products),
      signature: signature(order_number, date_in_ms, card_number, 1)
    }
  end

  def self.prepare_basket_body(order_number, card_number, line_items, date, products)
    date_in_ms = date.to_i * 1000
    {
      ver: 4,
      apiUser: ENV["SPL_API_USER"],
      apiToken: ENV["SPL_API_TOKEN"],
      partnerCode: ENV["SPL_PARTNER_CODE"],
      placeCode: ENV["SPL_PLACE_CODE"],
      mode: ENV["SPL_MODE"],
      date: date_in_ms,
      no: order_number,
      orderNo: order_number,
      reverse: false,
      pending: true,
      checkOnly: false,
      cardNo: card_number,
      basket: prepare_basket(line_items, products),
      signature: signature(order_number, date_in_ms, card_number)
    }
  end

  def self.prepare_basket(line_items, products)
    basket = line_items.map do |item|
      not_promoted = false
      products.each do |product|
        if product.variants.empty?
          product.variants.each do |var|
            if (var.id == item["variant_id"]) && (var.price != var.compare_at_price) && var.compare_at_price.to_i.positive?
              not_promoted = true
            end
          end
        else
          var = product.default_variant
          if (var.id == item["variant_id"]) && (var.price != var.compare_at_price) && var.compare_at_price.to_i.positive?
            not_promoted = true
          end
        end
      end

      {
        pos: item.id,
        quantity: item.quantity,
        productCode: item.sku,
        amountGross: item.price.to_f,
        notPromoted: not_promoted,
      }
    end
    Rails.logger.debug basket.inspect

    basket
  end

  def self.signature(order_number, date, card_number = '', check_only = '')
    # data= "YES_CZECOMM1388574855000123456719004762922649"
    data = "#{ENV["SPL_PARTNER_CODE"]}#{ENV["SPL_PLACE_CODE"]}#{date}#{order_number}#{check_only}#{card_number}"
    puts data.inspect
    signature_base = Digest::SHA256.hexdigest(data)
    Digest::SHA256.hexdigest(signature_base+ENV["SPL_POS_KEY"])
  end
end
