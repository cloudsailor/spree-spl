# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Adjustable::AdjustmentsUpdater, type: :model do
  # Use the upstream Spree approach to avoid store/product validation issues
  let(:order) { create(:order_with_line_items, line_items_count: 1) }
  let(:line_item) { order.line_items.first }

  subject(:updater) { described_class.new(adjustable) }

  describe '#line_item_with_spl_adjustments? (private)' do
    def line_item_with_spl_adjustments?
      updater.send(:line_item_with_spl_adjustments?)
    end

    context 'when adjustable is a line item with an SPL adjustment' do
      let(:adjustable) { line_item }

      before do
        create(:adjustment, order: order, adjustable: line_item, source_type: 'SPL', eligible: true, amount: -2.to_d)
      end

      it 'returns true' do
        expect(line_item_with_spl_adjustments?).to eq(true)
      end
    end

    context 'when adjustable is a line item without SPL adjustments' do
      let(:adjustable) { line_item }

      before do
        create(:adjustment, order: order, adjustable: line_item, source_type: 'Promo', eligible: true, amount: -2.to_d)
      end

      it 'returns false' do
        expect(line_item_with_spl_adjustments?).to eq(false)
      end
    end

    context 'when adjustable is not a line item' do
      let(:adjustable) { order }

      before do
        create(:adjustment, order: order, adjustable: order, source_type: 'SPL', eligible: true, amount: -2.to_d)
      end

      it 'returns false' do
        expect(line_item_with_spl_adjustments?).to eq(false)
      end
    end
  end

  describe '#recalculate_spl_adjustments (private)' do
    def recalculate_spl_adjustments(attributes, totals)
      updater.send(:recalculate_spl_adjustments, attributes, totals)
    end

    let(:adjustable) { line_item }

    let!(:spl_adj1) do
      create(:adjustment,
             order: order,
             adjustable: line_item,
             source_type: 'SPL',
             eligible: true,
             amount: 10.to_d)
    end

    let!(:spl_adj2) do
      create(:adjustment,
             order: order,
             adjustable: line_item,
             source_type: 'SPL',
             eligible: true,
             amount: -5.to_d)
    end

    let!(:spl_ineligible) do
      create(:adjustment,
             order: order,
             adjustable: line_item,
             source_type: 'SPL',
             eligible: false,
             amount: 100.to_d)
    end

    let!(:other_adj) do
      create(:adjustment,
             order: order,
             adjustable: line_item,
             source_type: 'Promo',
             eligible: true,
             amount: 50.to_d)
    end

    let(:attributes) { {} }
    let(:totals_hash) { { some_total: 123.to_d } }
    let(:fixed_time) { Time.zone.parse('2024-01-01 12:00:00') }
    let(:expected_total) { spl_adj1.amount + spl_adj2.amount }

    before do
      allow(Time).to receive(:current).and_return(fixed_time)
      allow(line_item).to receive(:update_columns)
      allow(updater).to receive(:assign_spl_totals).and_call_original
    end

    it 'sums only eligible SPL adjustments and passes the sum to assign_spl_totals' do
      recalculate_spl_adjustments(attributes, totals_hash)

      expect(updater).to have_received(:assign_spl_totals).with(
        attributes,
        expected_total,
        fixed_time
      )
    end

    it 'updates the adjustable using update_columns with provided totals' do
      recalculate_spl_adjustments(attributes, totals_hash)

      expect(line_item).to have_received(:update_columns).with(totals_hash)
    end

    it 'mutates attributes with adjustment_total, promo_total and updated_at' do
      recalculate_spl_adjustments(attributes, totals_hash)

      expect(attributes[:adjustment_total]).to eq(expected_total)
      expect(attributes[:promo_total]).to eq(expected_total)
      expect(attributes[:updated_at]).to eq(fixed_time)
    end
  end

  describe '#assign_spl_totals (private)' do
    def assign_spl_totals(attributes, total_amount, time)
      updater.send(:assign_spl_totals, attributes, total_amount, time)
    end

    let(:adjustable) { line_item }
    let(:attributes) { {} }
    let(:total_amount) { 42.5.to_d }
    let(:time) { Time.zone.parse('2024-02-02 10:00:00') }

    it 'sets adjustment_total, promo_total and updated_at' do
      assign_spl_totals(attributes, total_amount, time)

      expect(attributes[:adjustment_total]).to eq(total_amount)
      expect(attributes[:promo_total]).to eq(total_amount)
      expect(attributes[:updated_at]).to eq(time)
    end
  end
end
