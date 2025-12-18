# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Api::V2::Storefront::CheckoutController, type: :controller do
  describe 'private methods' do
    let(:order) { create(:order) }

    describe '#promotions_and_spl_adjustment_present?' do
      context 'when order has no promotions and no line items' do
        it 'returns false' do
          expect(
            controller.send(:promotions_and_spl_adjustment_present?, order)
          ).to eq(false)
        end
      end

      context 'when order has promotions but no line items' do
        before { create(:promotion, orders: [order]) }

        it 'returns false' do
          expect(
            controller.send(:promotions_and_spl_adjustment_present?, order)
          ).to eq(false)
        end
      end

      context 'when order has line items but no promotions' do
        let!(:line_item) { create(:line_item, order: order) }

        before do
          create(
            :adjustment,
            adjustable: line_item,
            source_type: 'SPL',
            amount: 10,
            order:
          )
        end

        it 'returns false' do
          expect(
            controller.send(:promotions_and_spl_adjustment_present?, order)
          ).to eq(false)
        end
      end

      context 'when order has promotions and line items but adjustments are not SPL' do
        let!(:promotion) { create(:promotion, orders: [order]) }
        let!(:line_item) { create(:line_item, order: order) }

        before do
          create(
            :adjustment,
            adjustable: line_item,
            source_type: 'Promotion', # not SPL
            amount: 10,
            order:
          )
        end

        it 'returns false' do
          expect(
            controller.send(:promotions_and_spl_adjustment_present?, order)
          ).to eq(false)
        end
      end

      context 'when order has promotions and SPL adjustment on at least one line item' do
        let!(:promotion) { create(:promotion, orders: [order]) }
        let!(:line_item1) { create(:line_item, order: order) }
        let!(:line_item2) { create(:line_item, order: order) }

        before do
          create(
            :adjustment,
            adjustable: line_item2,
            source_type: 'SPL',
            amount: 5,
            order:
          )
        end

        it 'returns true' do
          expect(
            controller.send(:promotions_and_spl_adjustment_present?, order)
          ).to eq(true)
        end
      end

      context 'when SPL adjustment exists but is soft-deleted or zero amount' do
        let!(:promotion) { create(:promotion, orders: [order]) }
        let!(:line_item) { create(:line_item, order: order) }

        before do
          create(
            :adjustment,
            adjustable: line_item,
            source_type: 'SPL',
            amount: 0,
            order:
          )
        end

        it 'still returns true (presence-based check)' do
          expect(
            controller.send(:promotions_and_spl_adjustment_present?, order)
          ).to eq(true)
        end
      end
    end

    describe '#promotion_switcher' do
      let(:service) { instance_double(PromotionSwitcherService, call: true) }
      context 'when check_only is true' do
        it 'calls PromotionSwitcherService with check_only=true' do
          expect(PromotionSwitcherService)
            .to receive(:new).with(order, true)
                             .and_return(service)

          controller.send(:promotion_switcher, order, true)
        end
      end

      context 'when check_only is false' do
        it 'calls PromotionSwitcherService with check_only=false' do
          expect(PromotionSwitcherService)
            .to receive(:new).with(order, false)
                             .and_return(service)

          controller.send(:promotion_switcher, order, false)
        end
      end

      context 'when service raises an error' do
        before do
          allow(PromotionSwitcherService)
            .to receive(:new)
            .and_raise(StandardError.new('unhandled error'))
        end

        it 'lets the error raise' do
          expect do
            controller.send(:promotion_switcher, order, true)
          end.to raise_error(StandardError, 'unhandled error')
        end
      end
    end
  end
end
