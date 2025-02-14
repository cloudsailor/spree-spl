# frozen_string_literal: true

module CartSerializerDecorator
  def self.prepended(base)
    base.has_many :adjustments, serializer: ::AdjustmentSerializer do |cart|
      cart.line_items.map(&:adjustments).flatten.uniq
    end
  end
end
