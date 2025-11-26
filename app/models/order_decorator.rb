# frozen_string_literal: true

module OrderDecorator
  def with_spl_adjustments?
    line_items.map { |li| li.adjustments.where(source_type: 'SPL') }.present?
  end
end
