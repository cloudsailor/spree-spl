# frozen_string_literal: true

module Spree
  module Adjustable
    module AdjustmentsUpdaterDecorator
      def persist_totals(totals)
        attributes = totals

        if @adjustable.is_a?(::Spree::Order) && @adjustable.public_metadata.key?(:spl_card_active)
          if @adjustable.public_metadata[:spl_card_active] == true
            @adjustable.adjustments.update_all(eligible: false)
          else
            @adjustable.adjustments.update_all(eligible: true)
            
            super
          end
        end

        recalculate_spl_adjustments(attributes, totals) if @adjustable.is_a?(::Spree::LineItem) && @adjustable.adjustments.any? { |adj| adj.source_type == "SPL" }
      end

      private

      def recalculate_spl_adjustments(attributes, totals)
        sparta_adjustments = @adjustable.adjustments.select { |adj| adj.source_type == "SPL" && adj.eligible? }
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
