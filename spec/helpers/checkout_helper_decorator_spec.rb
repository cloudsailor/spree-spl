# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckoutHelperDecorator, type: :helper do
  let(:order) { create(:order) }
  let(:variant) { create(:variant) }
  let(:line_item) { create(:line_item, order: order, variant: variant) }

  describe '#spl_adjustment' do
    subject(:result) { helper.spl_adjustment(line_item) }

    context 'when SPL adjustment exists' do
      let!(:spl_adjustment) do
        line_item.adjustments.create!(
          preferred_external_source_type: 'SPL',
          amount: -5,
          label: 'SPARTA_V777.90CRAZY_347',
          eligible: true,
          state: 'open',
          order: order
        )
      end

      let!(:other_adjustment) do
        line_item.adjustments.create!(
          preferred_external_source_type: 'Promotion',
          amount: -3,
          label: 'Promotion',
          eligible: true,
          state: 'open',
          order: order
        )
      end

      it 'returns the SPL adjustment' do
        expect(result).to eq(spl_adjustment)
      end
    end

    context 'when SPL adjustment does not exist' do
      let!(:promotion_adjustment) do
        line_item.adjustments.create!(
          preferred_external_source_type: 'Promotion',
          amount: -3,
          label: 'Promotion',
          eligible: true,
          state: 'open',
          order: order
        )
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end

  describe '#promotion_name' do
    subject(:result) { helper.promotion_name(adjustment) }

    context 'when label contains dot notation' do
      let(:adjustment) { build_stubbed(:adjustment, label: 'SPARTA_V777.80CRAZY_347') }

      it 'returns the last segment of the label' do
        expect(result).to eq('80CRAZY_347')
      end
    end

    context 'when label does not contain dots' do
      let(:adjustment) { build_stubbed(:adjustment, label: 'SIMPLE_DISCOUNT') }

      it 'returns the whole label' do
        expect(result).to eq('SIMPLE_DISCOUNT')
      end
    end
  end
end
