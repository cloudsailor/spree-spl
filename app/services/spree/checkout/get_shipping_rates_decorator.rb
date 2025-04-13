# frozen_string_literal: true

module Spree
  module Checkout
    module GetShippingRatesDecorator
      private

      def spl_cart_active?(order)
        return unless order.public_metadata.key?(:spl_card_active)

        ActiveModel::Type::Boolean.new.cast(order.public_metadata[:spl_card_active])
      end
    end
  end
end
