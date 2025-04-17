# frozen_string_literal: true

module CartDecorator
  private

  def order_spl?
    if order.public_metadata.key?(:spl_no_card) && order.public_metadata.key?(:spl_card_active)
      order.public_metadata['spl_card_active']
    else
      false
    end
  end
end
