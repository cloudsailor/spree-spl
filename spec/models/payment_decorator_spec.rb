# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Payment, type: :model do
  let(:store) { Spree::Store.default || create(:store, default: true) }

  let(:public_metadata) { {} }

  let(:order) do
    create(
      :order,
      store: store,
      public_metadata: public_metadata
    )
  end

  subject(:decorated_payment) { described_class.new(order: order) }

  let(:service_instance) { instance_double(PromotionSwitcherService, call: service_result) }
  let(:service_result) { :some_result }

  before do
    allow(PromotionSwitcherService).to receive(:new).and_return(service_instance)
    allow(UpdateSpartaStateJob).to receive(:perform_later)
  end

  describe '#promotion_switcher (private)' do
    def run_promotion_switcher(check_only)
      decorated_payment.send(:promotion_switcher, order, check_only)
    end

    context 'when both keys exist and spl_card_active is true (symbol keys)' do
      let(:public_metadata) { { spl_no_card: '1234567890123', spl_card_active: true } }

      it 'initializes PromotionSwitcherService with order and check_only and calls it' do
        result = run_promotion_switcher(true)

        expect(PromotionSwitcherService).to have_received(:new).with(order, true)
        expect(service_instance).to have_received(:call)
        expect(result).to eq(service_result)
      end

      it 'passes false correctly as check_only flag' do
        run_promotion_switcher(false)

        expect(PromotionSwitcherService).to have_received(:new).with(order, false)
      end
    end

    context 'when both keys exist but spl_card_active is true (string keys)' do
      let(:public_metadata) { { 'spl_no_card' => '1234567890123', 'spl_card_active' => true } }

      it 'initializes PromotionSwitcherService with order and check_only and calls it' do
        result = run_promotion_switcher(true)

        expect(result).to eq(service_result)
        expect(PromotionSwitcherService).to have_received(:new)
        expect(service_instance).to have_received(:call)
      end

      it 'passes false correctly as check_only flag' do
        run_promotion_switcher(false)

        expect(PromotionSwitcherService).to have_received(:new).with(order, false)
      end
    end

    context 'when both keys exist but spl_card_active is false (symbol keys)' do
      let(:public_metadata) { { spl_no_card: '1234567890123', spl_card_active: false } }

      it 'does not initialize PromotionSwitcherService' do
        result = run_promotion_switcher(true)

        expect(result).to be_nil
        expect(PromotionSwitcherService).not_to have_received(:new)
        expect(service_instance).not_to have_received(:call)
      end
    end

    context 'when only one of required keys is present' do
      context 'when spl_no_card present but spl_card_active missing' do
        let(:public_metadata) { { spl_no_card: '1234567890123' } }

        it 'does nothing and returns nil' do
          result = run_promotion_switcher(true)

          expect(result).to be_nil
          expect(PromotionSwitcherService).not_to have_received(:new)
        end
      end

      context 'when spl_card_active present but spl_no_card missing' do
        let(:public_metadata) { { spl_card_active: '1234567890123' } }

        it 'does nothing and returns nil' do
          result = run_promotion_switcher(true)

          expect(result).to be_nil
          expect(PromotionSwitcherService).not_to have_received(:new)
        end
      end
    end

    context 'when public_metadata is empty' do
      let(:public_metadata) { {} }

      it 'returns nil and does nothing' do
        result = run_promotion_switcher(true)

        expect(result).to be_nil
        expect(PromotionSwitcherService).not_to have_received(:new)
      end
    end
  end

  describe '#update_sparta_state (private)' do
    def run_update_sparta_state
      decorated_payment.send(:update_sparta_state)
    end

    context 'when both keys exist and spl_card_active is true (symbol keys)' do
      let(:public_metadata) { { spl_no_card: '1234567890123', spl_card_active: true } }

      it 'enqueues UpdateSpartaStateJob with D state' do
        run_update_sparta_state

        expect(UpdateSpartaStateJob).to have_received(:perform_later).with(
          order.token,
          'D',
          order.number,
          order.store
        )
      end
    end

    context 'when both keys exist and spl_card_active is true (string keys)' do
      let(:public_metadata) { { 'spl_no_card' => '1234567890123', 'spl_card_active' => true } }

      it 'enqueues UpdateSpartaStateJob with D state' do
        run_update_sparta_state

        expect(UpdateSpartaStateJob).to have_received(:perform_later).with(
          order.token,
          'D',
          order.number,
          order.store
        )
      end
    end

    context 'when both keys exist but spl_card_active is false (symbol keys)' do
      let(:public_metadata) { { spl_no_card: '1234567890123', spl_card_active: false } }

      it 'does not enqueue UpdateSpartaStateJob' do
        run_update_sparta_state

        expect(UpdateSpartaStateJob).not_to have_received(:perform_later)
      end
    end

    context 'when only one of required keys is present' do
      context 'when spl_no_card present but spl_card_active missing' do
        let(:public_metadata) { { spl_no_card: '1234567890123' } }

        it 'does not enqueue UpdateSpartaStateJob' do
          run_update_sparta_state

          expect(UpdateSpartaStateJob).not_to have_received(:perform_later)
        end
      end

      context 'when spl_card_active present but spl_no_card missing' do
        let(:public_metadata) { { spl_card_active: true } }

        it 'does not enqueue UpdateSpartaStateJob' do
          run_update_sparta_state

          expect(UpdateSpartaStateJob).not_to have_received(:perform_later)
        end
      end
    end

    context 'when public_metadata is empty' do
      let(:public_metadata) { {} }

      it 'does not enqueue UpdateSpartaStateJob' do
        run_update_sparta_state

        expect(UpdateSpartaStateJob).not_to have_received(:perform_later)
      end
    end
  end
end
