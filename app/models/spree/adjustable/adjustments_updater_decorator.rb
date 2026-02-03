# frozen_string_literal: true

module Spree
  module Adjustable
    module AdjustmentsUpdaterDecorator
      SPL_SOURCE_TYPE = 'SPL'

      private

      def set_spree_adjustments
        @adjustable.is_a?(::Spree::Order) ? @adjustable : @adjustable.order
      end

      def line_item_with_spl_adjustments?
        @adjustable.is_a?(::Spree::LineItem) && @adjustable.adjustments.any? { |adj| adj.source_type == SPL_SOURCE_TYPE }
      end

      def recalculate_spl_adjustments(attributes, totals)
        sparta_adjustments = @adjustable.adjustments.select do |adj|
          adj.source_type == SPL_SOURCE_TYPE && adj.eligible?
        end
        total_adjustment_amount = sparta_adjustments.sum(&:amount)
        assign_spl_totals(attributes, total_adjustment_amount, Time.current)
        @adjustable.update_columns(totals)
      end

      def assign_spl_totals(attributes, total_amount, time)
        attributes[:adjustment_total] = total_amount
        attributes[:promo_total] = total_amount
        attributes[:updated_at] = time
      end
    end
  end
end
