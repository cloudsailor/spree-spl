# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Adjustable::AdjustmentsUpdater, type: :model do

  let(:store) { Spree::Store.default || create(:store, default: true) }
  let(:public_metadata) { {} }

  let!(:order) do
    create(
      :order,
      store: store,
      public_metadata: public_metadata
    )
  end
  let(:adjustable) { order }
  subject(:updater) { described_class.new(adjustable) }


  describe '#set_spree_adjustments (private)' do
    def run_set_spree_adjustments
      updater.send(:set_spree_adjustments)
    end
    before do
      order.adjustments = adjustments
      shipment.adjustments << shipment_adjustment
      order.save
      shipment.save
    rescue;end;

    context 'when adjustable is an order with spl_card_active: true (symbol key)' do
      let(:public_metadata) { { spl_card_active: true } }
      let(:adjustments) { [adjustment1, adjustment2]}
      let(:adjustment1) { create(:adjustment, order: order) }
      let(:adjustment2) { create(:adjustment, order: order) }

      it 'destroys all adjustments on the order' do
        expect { run_set_spree_adjustments }
          .to change { order.adjustments.reload.count }.from(2).to(0)
      end
    end

    context 'when adjustable is an order with spl_card_active: true (string key)' do
      let(:public_metadata) { { 'spl_card_active' => true } }
      let(:adjustments) { [adjustment1, adjustment2]}
      let(:adjustment1) { create(:adjustment, order: order) }
      let(:adjustment2) { create(:adjustment, order: order) }

      it 'destroys all adjustments on the order' do
        expect { run_set_spree_adjustments }
          .to change { order.adjustments.reload.count }.from(2).to(0)
      end
    end

    context 'when adjustable is an order with spl_card_active: false' do
      let(:public_metadata) { { spl_card_active: false } }
      let(:adjustments) { [adjustment]}
      let!(:adjustment) { create(:adjustment, order: order, adjustable: order) }

      it 'does not destroy adjustments' do
        expect { run_set_spree_adjustments }
          .not_to change { order.adjustments.reload.count }.from(1)
      end
    end

    context 'when adjustable is a shipment and order has spl_card_active: true' do
      let(:public_metadata) { { spl_card_active: true } }
      let(:adjustable) { shipment }
      let!(:shipment) { create(:shipment, order: order) }
      let(:adjustments) { [order_adjustment]}
      let!(:shipment_adjustment) { create(:adjustment, order: order, adjustable: shipment) }
      let!(:order_adjustment)    { create(:adjustment, order: order, adjustable: order) }

      it 'destroys only the shipment adjustments, not order adjustments' do
        expect {
          run_set_spree_adjustments
        }.to change { shipment.adjustments.reload.count }.from(1).to(0)

        expect {
          run_set_spree_adjustments
        }.not_to(change { order.adjustments.reload.count })
      end
    end

    context 'when adjustable is a line item and order has spl_card_active: true' do
      let(:public_metadata) { { spl_card_active: true } }

      let(:adjustable) { line_item }

      let(:line_item) { create(:line_item) }
      let(:line_item_adjustment) { create(:adjustment, order: order, adjustable: line_item) }
      let(:order_adjustment)     { create(:adjustment, order: order, adjustable: order) }

      it 'destroys only the line item adjustments, not order adjustments' do
        line_item.adjustments << line_item_adjustment
        line_item.save
        order.adjustments << order_adjustment
        order.line_items << line_item
        order.save

        expect { run_set_spree_adjustments }
          .to change { line_item.adjustments.reload.count }.from(1).to(0)

      end
    end

    context 'when order has no spl_card_active key' do
      let(:public_metadata) { {} }

      let!(:adjustment) { create(:adjustment, order: order, adjustable: order) }

      it 'does nothing' do
        expect { run_set_spree_adjustments }
          .not_to change { order.adjustments.reload.count }.from(1)
      end
    end
  end

  describe '#shipment_with_adjustments? (private)' do
    def shipment_with_adjustments?
      updater.send(:shipment_with_adjustments?)
    end

    context 'when adjustable is a shipment and order has spl_card_active key as symbol' do
      let(:public_metadata) { { spl_card_active: true } }
      let(:adjustable)      { shipment }
      let!(:shipment)       { create(:shipment, order: order) }

      it 'returns true' do
        expect(shipment_with_adjustments?).to eq(true)
      end
    end

    context 'when adjustable is a shipment and order has spl_card_active key as string' do
      let(:public_metadata) { { 'spl_card_active' => true } }
      let(:adjustable)      { shipment }
      let!(:shipment)       { create(:shipment, order: order) }

      it 'returns true' do
        expect(shipment_with_adjustments?).to eq(true)
      end
    end

    context 'when adjustable is a shipment but order has no key' do
      let(:public_metadata) { {} }
      let(:adjustable)      { shipment }
      let!(:shipment)       { create(:shipment, order: order) }

      it 'returns false' do
        expect(shipment_with_adjustments?).to eq(false)
      end
    end

    context 'when adjustable is not a shipment' do
      let(:public_metadata) { { spl_card_active: true } }
      let(:adjustable)      { order }

      it 'returns false' do
        expect(shipment_with_adjustments?).to eq(false)
      end
    end
  end

  describe '#order_with_adjustments? (private)' do
    def order_with_adjustments?
      updater.send(:order_with_adjustments?)
    end

    context 'when adjustable is an order and it has spl_card_active key as symbol' do
      let(:public_metadata) { { spl_card_active: true } }

      it 'returns true' do
        expect(order_with_adjustments?).to eq(true)
      end
    end

    context 'when adjustable is an order and it has spl_card_active key as string' do
      let(:public_metadata) { { 'spl_card_active' => true } }

      it 'returns true' do
        expect(order_with_adjustments?).to eq(true)
      end
    end

    context 'when adjustable is an order without that key' do
      let(:public_metadata) { {} }

      it 'returns false' do
        expect(order_with_adjustments?).to eq(false)
      end
    end

    context 'when adjustable is not an order' do
      let(:public_metadata) { { spl_card_active: true } }
      let(:adjustable)      { create(:shipment, order: order) }

      it 'returns false' do
        expect(order_with_adjustments?).to eq(false)
      end
    end
  end

  describe '#line_item_with_spl_adjustments? (private)' do
    def line_item_with_spl_adjustments?
      updater.send(:line_item_with_spl_adjustments?)
    end

    before do
      line_item.adjustments << line_item_adjustment
      line_item.save
      order.line_items << line_item
      order.save
    rescue;end;


    context 'when adjustable is a line item with SPL adjustment' do
      let(:adjustable) { line_item }
      let(:line_item) { create(:line_item) }
      let(:line_item_adjustment) do
        create(:adjustment,
               order: order,
               adjustable: line_item,
               source_type: 'SPL')
      end

      it 'returns true' do
        expect(line_item_with_spl_adjustments?).to eq(true)
      end
    end

    context 'when adjustable is a line item with non-SPL adjustments only' do
      let(:adjustable) { line_item }
      let(:line_item) { create(:line_item) }

      let(:line_item_adjustment) do
        create(:adjustment,
               order: order,
               adjustable: line_item,
               source_type: 'Promo')
      end

      it 'returns false' do
        expect(line_item_with_spl_adjustments?).to eq(false)
      end
    end

    context 'when adjustable is not a line item but has SPL adjustments' do
      let(:adjustable) { order }

      let!(:spl_adj) do
        create(:adjustment,
               order: order,
               adjustable: order,
               source_type: 'SPL')
      end

      it 'returns false' do
        expect(line_item_with_spl_adjustments?).to eq(false)
      end
    end
  end


  describe '#recalculate_spl_adjustments (private)' do
    before do
      line_item.adjustments = adjustments
      line_item.save
      order.line_items << line_item
      order.save
    rescue;end;

    def recalculate_spl_adjustments(attributes, totals)
      updater.send(:recalculate_spl_adjustments, attributes, totals)
    end

    let(:adjustable) { line_item }
    let!(:line_item) { create(:line_item) }
    let(:adjustments){
      [ spl_adj1, spl_adj2 , spl_ineligible, other_adj]
    }

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

    before do
      allow(Time).to receive(:current).and_return(fixed_time)
      allow(line_item).to receive(:update_columns)
      allow(updater).to receive(:assign_spl_totals).and_call_original
    end

    it 'sums only eligible SPL adjustments and passes them to assign_spl_totals' do
      expected_total = spl_adj1.amount + spl_adj2.amount

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

    it 'mutates attributes to contain adjustment_total, promo_total and updated_at' do
      expected_total = spl_adj1.amount + spl_adj2.amount

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
