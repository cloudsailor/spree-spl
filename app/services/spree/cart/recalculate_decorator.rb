# frozen_string_literal: true

module Spree
  module Cart
    module RecalculateDecorator
      private

      def spl_cart_active?(order)
        return unless order.public_metadata.key?(:spl_card_active) # rubocop:disable Style/ReturnNilInPredicateMethodDefinition

        ActiveModel::Type::Boolean.new.cast(order.public_metadata[:spl_card_active])
      end
    end
  end
end
