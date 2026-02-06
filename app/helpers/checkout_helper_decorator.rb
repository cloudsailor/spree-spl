# frozen_string_literal: true

module CheckoutHelperDecorator
  SPL_SOURCE_TYPE = 'SPL'.freeze

  def spl_adjustment(line_item)
    line_item.adjustments.find_by("preferences LIKE ?", "%:external_source_type: #{SPL_SOURCE_TYPE}%")

  end

  def promotion_name(adjustment)
    adjustment.label.split('.').last
  end
end
