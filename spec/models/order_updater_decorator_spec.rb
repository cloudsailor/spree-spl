# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::OrderUpdater, type: :model do
  before(:all) do
    # Ensure decorator is applied, but harmless if already prepended by Rails
    Spree::OrderUpdater.prepend(OrderUpdaterDecorator) unless Spree::OrderUpdater < OrderUpdaterDecorator
  end

  let(:store) { Spree::Store.default || create(:store, default: true) }

  let!(:order) do
    create(
      :order,
      store: store,
      payment_state: payment_state,
      state: order_state,
      public_metadata: public_metadata
    )
  end
  let(:adjustments) { [] }

  let(:payment_state)  { nil }
  let(:order_state)    { 'cart' }
  let(:public_metadata) { {} }

  subject(:updater) { described_class.new(order) }

  before do
    allow(UpdateSpartaStateJob).to receive(:perform_later)
  end

  describe '#update' do
    context "when payment_state is 'paid'" do
      let(:payment_state) { 'paid' }

      it "calls UpdateSpartaStateJob with 'D'" do
        updater.update

        expect(UpdateSpartaStateJob).to have_received(:perform_later).with(
          order.token,
          'D',
          order.number,
          order.store
        )
      end
    end

    context "when order is 'canceled'" do
      let(:order_state) { 'canceled' }

      it "calls UpdateSpartaStateJob with 'C'" do
        updater.update

        expect(UpdateSpartaStateJob).to have_received(:perform_later).with(
          order.token,
          'C',
          order.number,
          order.store
        )
      end
    end

    context 'when both paid and canceled' do
      let(:payment_state) { 'paid' }
      let(:order_state)   { 'canceled' }

      it 'calls the job twice with both states' do
        updater.update

        expect(UpdateSpartaStateJob).to have_received(:perform_later).with(
          order.token, 'D', order.number, order.store
        )

        expect(UpdateSpartaStateJob).to have_received(:perform_later).with(
          order.token, 'C', order.number, order.store
        )
      end
    end

    context 'when neither paid nor canceled' do
      let(:payment_state) { 'balance_due' }
      let(:order_state)   { 'complete' }

      it 'does not call UpdateSpartaStateJob' do
        updater.update

        expect(UpdateSpartaStateJob).not_to have_received(:perform_later)
      end
    end
  end

  describe '#check_spl_adjustments' do
    def run_check
      updater.send(:check_spl_adjustments)
    end

    context 'when spl_card_active is false' do
      let(:public_metadata) { { 'spl_card_active' => false } }
      let(:adjustments) { [adjustment] }

      let(:adjustment) do
        create(:adjustment, source_type: 'Promo', order:, eligible: true)
      end

      it 'returns false and does nothing' do
        order.adjustments = adjustments
        order.save
        expect(run_check).to eq(false)
        expect(adjustment.reload.eligible).to eq(true)
      end
    end

    context 'when spl_card_active is true with eligible non-SPL adjustments' do
      let(:public_metadata) { { 'spl_card_active' => true } }
      let(:adjustments) { [spl_adj, promo_adj, promo_inelig] }

      let(:spl_adj)        { create(:adjustment, order:, source_type: 'SPL', eligible: true) }
      let(:promo_adj)      { create(:adjustment, order:, source_type: 'Promo', eligible: true) }
      let(:promo_inelig)   { create(:adjustment, order:, source_type: 'Promo', eligible: false) }

      it 'returns true only if non-SPL eligible adjustments were changed' do
        order.adjustments = adjustments
        order.save
        expect(run_check).to eq(true)
        expect(promo_adj.reload.eligible).to eq(false)
        expect(spl_adj.reload.eligible).to eq(true)
        expect(promo_inelig.reload.eligible).to eq(false)
      end
    end

    context 'when spl_card_active is true but no eligible non-SPL adjustments' do
      let(:public_metadata) { { 'spl_card_active' => true } }
      let(:adjustments) { [spl_adj, promo_inelig] }

      let(:spl_adj)      { create(:adjustment, order:, source_type: 'SPL', eligible: true) }
      let(:promo_inelig) { create(:adjustment, order:, source_type: 'Promo', eligible: false) }

      it 'returns false' do
        order.adjustments = adjustments
        order.save
        expect(run_check).to eq(false)
      end
    end

    context 'when public_metadata does not contain key' do
      let(:public_metadata) { {} }
      let(:adjustments) { [promo_adj] }
      let(:promo_adj) { create(:adjustment, order:, source_type: 'Promo', eligible: true) }

      it 'returns false and does nothing' do
        order.adjustments = adjustments
        order.save
        expect(run_check).to eq(false)
        expect(promo_adj.reload.eligible).to eq(true)
      end
    end
  end
end
