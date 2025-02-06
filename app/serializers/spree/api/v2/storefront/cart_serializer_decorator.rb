# frozen_string_literal: true

module Spree
  module V2
    module Storefront
      module CartSerializerDecorator
        def self.prepended(base)
          base.has_many :adjustments, serializer: Spree::V2::Storefront::AdjustmentSerializer do |cart|
            cart.line_items.map(&:adjustments).flatten.uniq
          end
        end
      end
    end
  end
end

if ::Spree::V2::Storefront::CartSerializer.included_modules.exclude?(Spree::V2::Storefront::CartSerializerDecorator)
  ::Spree::V2::Storefront::CartSerializer.prepend Spree::V2::Storefront::CartSerializerDecorator
end
