# frozen_string_literal: true

module Spree
  module Adjustable
    module AdjustmentsUpdaterDecorator
      def persist_totals(totals)
        attributes = totals

        set_spree_adjustments if shipment_with_adjustments? || order_with_adjustments?
        recalculate_spl_adjustments(attributes, totals) if line_item_with_spl_adjustments?
      end

      private

      def set_spree_adjustments
        adjustable = @adjustable.is_a?(::Spree::Order) ? @adjustable : @adjustable.order
        if adjustable.public_metadata[:spl_card_active] == true
          @adjustable.adjustments.update_all(eligible: false)
        else
          @adjustable.adjustments.update_all(eligible: true)

          super
        end
      end

      def shipment_with_adjustments?
        @adjustable.is_a?(::Spree::Shipment) && @adjustable.order.public_metadata.key?(:spl_card_active)
      end

      def order_with_adjustments?
        @adjustable.is_a?(::Spree::Order) && @adjustable.public_metadata.key?(:spl_card_active)
      end

      def line_item_with_spl_adjustments?
        @adjustable.is_a?(::Spree::LineItem) && @adjustable.adjustments.any? { |adj| adj.source_type == "SPL" }
      end

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
