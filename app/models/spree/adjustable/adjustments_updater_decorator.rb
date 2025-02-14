# frozen_string_literal: true

module Spree
  module Adjustable
    module AdjustmentsUpdaterDecorator
      def persist_totals(totals) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        attributes = totals

        if @adjustable.is_a?(::Spree::LineItem) && @adjustable.adjustments.any? { |adj| adj.label&.start_with?("SPARTA") } # rubocop:disable Style/GuardClause
          sparta_adjustments = @adjustable.adjustments.select { |adj| adj.label&.start_with?("SPARTA") && adj.eligible? }
          total_adjustment_amount = sparta_adjustments.sum(&:amount)
          attributes[:adjustment_total] = total_adjustment_amount
          attributes[:promo_total] = total_adjustment_amount
          attributes[:updated_at] = Time.current
          @adjustable.update_columns(totals)
        end
      end
    end
  end
end
