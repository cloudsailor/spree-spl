# frozen_string_literal: true

module CheckoutHelperDecorator
  def spl_adjustment(line_item)
    line_item.adjustments.find_by(source_type: 'SPL')
  end

  def promotion_name(adjustment)
    adjustment.label.split('.').last
  end
end
