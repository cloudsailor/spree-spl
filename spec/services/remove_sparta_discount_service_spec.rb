# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RemoveSpartaDiscountService do
  let(:country) { create(:country) }
  let(:store)    { create(:store, default_country: country) }
  let(:order)    { create(:order, store: store) }

  let(:variant1) { create(:variant, price: 10) }
  let(:variant2) { create(:variant, price: 20) }

  let!(:line_item1) { create(:line_item, order: order, variant: variant1, quantity: 1, price: 10) }
  let!(:line_item2) { create(:line_item, order: order, variant: variant2, quantity: 2, price: 20) }

  before do
    allow(Spree::Dependencies).to receive(:cart_recalculate_service).and_return('FakeCartRecalculateService')
    stub_const('FakeCartRecalculateService', Class.new do
      def self.call(order:, line_item: nil); end
    end)
  end

  describe '.destroy_all_sparta_adjustments' do
    let!(:spl_adj_li1) do
      line_item1.adjustments.create!(
        source_type: 'SPL',
        amount: -5,
        label: 'SPARTA_DISCOUNT_LI1',
        eligible: true,
        state: 'open',
        order: order
      )
    end

    let!(:non_spl_adj_li1) do
      line_item1.adjustments.create!(
        source_type: 'Promotion',
        amount: -3,
        label: 'PROMO_LI1',
        eligible: true,
        state: 'open',
        order: order
      )
    end

    let!(:non_spl_adj_li2) do
      line_item2.adjustments.create!(
        source_type: 'Promotion',
        amount: -4,
        label: 'PROMO_LI2',
        eligible: true,
        state: 'open',
        order: order
      )
    end

    it 'removes all SPL adjustments from all line items, leaves non-SPL and recalculates cart for affected items' do
      expect(line_item1.adjustments.count).to eq(2)
      expect(line_item2.adjustments.count).to eq(1)
      expect(FakeCartRecalculateService).to receive(:call).with(order: order, line_item: line_item1).at_least(:once)

      described_class.destroy_all_sparta_adjustments(order)
      line_item1.reload
      line_item2.reload

      expect(line_item1.adjustments.where(source_type: 'SPL')).to be_empty
      expect(line_item1.adjustments.where(source_type: 'Promotion').count).to eq(1)
      expect(line_item2.adjustments.where(source_type: 'Promotion').count).to eq(1)
    end

    it 'does nothing when there are no SPL adjustments' do
      spl_adj_li1.destroy
      line_item1.reload

      expect(FakeCartRecalculateService).not_to receive(:call)

      described_class.destroy_all_sparta_adjustments(order)

      expect(line_item1.adjustments.where(source_type: 'Promotion').count).to eq(1)
      expect(line_item2.adjustments.where(source_type: 'Promotion').count).to eq(1)
    end
  end

  describe '.destroy_inactive_adjustments' do
    let!(:spl_adj1) do
      line_item1.adjustments.create!(
        source_type: 'SPL',
        amount: -5,
        label: 'SPARTA_DISCOUNT_1',
        eligible: true,
        state: 'open',
        order: order
      )
    end

    let!(:spl_adj2) do
      line_item1.adjustments.create!(
        source_type: 'SPL',
        amount: -2,
        label: 'SPARTA_DISCOUNT_2',
        eligible: false,
        state: 'closed',
        order: order
      )
    end

    let(:relation) { line_item1.adjustments.where(source_type: 'SPL') }

    it 'marks eligible SPL adjustments as ineligible & closed, recalculates cart, then destroys all given adjustments' do # rubocop:disable Layout/LineLength
      expect(line_item1.adjustments.where(source_type: 'SPL').count).to eq(2)
      expect(FakeCartRecalculateService).to receive(:call).with(order: order, line_item: line_item1).twice

      described_class.destroy_inactive_adjustments(relation, line_item1, order)
      line_item1.reload

      expect(line_item1.adjustments.where(source_type: 'SPL')).to be_empty
    end

    it 'is safe when relation is empty' do
      empty_relation = line_item2.adjustments.where(source_type: 'SPL')

      expect do
        described_class.destroy_inactive_adjustments(empty_relation, line_item2, order)
      end.not_to raise_error
    end
  end

  describe '.destroy_not_spl_adjustments' do
    let!(:spl_adj_li1) do
      line_item1.adjustments.create!(
        source_type: 'SPL',
        amount: -5,
        label: 'SPARTA_DISCOUNT_LI1',
        eligible: true,
        state: 'open',
        order: order
      )
    end

    let!(:non_spl_adj_li1) do
      line_item1.adjustments.create!(
        source_type: 'Promotion',
        amount: -3,
        label: 'PROMO_LI1',
        eligible: true,
        state: 'open',
        order: order
      )
    end

    let!(:non_spl_adj_li2) do
      line_item2.adjustments.create!(
        source_type: 'Promotion',
        amount: -4,
        label: 'PROMO_LI2',
        eligible: true,
        state: 'open',
        order: order
      )
    end

    context 'when order has at least one SPL adjustment' do
      it 'removes all non-SPL adjustments from all line items' do
        expect(line_item1.adjustments.count).to eq(2)
        expect(line_item2.adjustments.count).to eq(1)

        described_class.destroy_not_spl_adjustments(order)

        line_item1.reload
        line_item2.reload

        expect(line_item1.adjustments.where(source_type: 'SPL').count).to eq(1)
        expect(line_item1.adjustments.where.not(source_type: 'SPL')).to be_empty
        expect(line_item2.adjustments).to be_empty
      end
    end

    context 'when order has no SPL adjustments' do
      before do
        spl_adj_li1.destroy
        line_item1.reload
      end

      it 'does nothing and keeps all adjustments' do
        expect do
          described_class.destroy_not_spl_adjustments(order)
        end.not_to(change { Spree::Adjustment.count })

        expect(line_item1.adjustments.where(source_type: 'Promotion').count).to eq(1)
        expect(line_item2.adjustments.where(source_type: 'Promotion').count).to eq(1)
      end
    end
  end
end
