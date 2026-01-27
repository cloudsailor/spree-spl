# frozen_string_literal: true

module CartDecorator
  private

  def order_spl?
    symbolized_keys = order.public_metadata.to_h.deep_symbolize_keys
    if symbolized_keys.key?(:spl_no_card) && symbolized_keys.key?(:spl_card_active)
      symbolized_keys[:spl_card_active]
    else
      false
    end
  end
end
