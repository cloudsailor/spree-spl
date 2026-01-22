# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spl::ValidateCardService do
  subject(:service) { described_class.new(card_number, user, store) }

  let(:country) { create(:country) }
  let(:store) { create(:store, default_country: country) }
  let(:user) { create(:user, public_metadata: { 'spl_no_card' => '1234567890123', 'spl_card_active' => true }) }
  let(:card_number) { '1234567890123' }

  before do
    allow(service).to receive(:verify_card_request).and_return(
      { errorCode: '0', response: { card: { status: 'A' } } }.to_json
    )
    allow(service).to receive(:cards_assigned_user).and_return(nil)
  end

  describe '#call' do
    it 'temporarily disables spl_card_active during validation' do
      original_value = user.public_metadata['spl_card_active']
      service.call

      expect(user.public_metadata['spl_card_active']).to eq(original_value)
    end

    context 'when API returns error' do
      before do
        allow(service).to receive(:verify_card_request).and_return({ errorCode: '1', msg: 'Invalid card' }.to_json)
      end

      it 'restores spl_card_active and saves user' do
        expect { service.call }.to raise_error(Spl::ValidateCardService::SplCardValidationError)

        user.reload
        expect(user.public_metadata['spl_card_active']).to eq(false)
      end
    end

    context "when card status is not 'A'" do
      before do
        allow(service).to receive(:verify_card_request).and_return(
          { errorCode: '0', response: { card: { status: 'B' } } }.to_json
        )
      end

      it 'raises SplCardValidationError and restores spl_card_active' do
        expect do
          service.call
        end.to raise_error(
          Spl::ValidateCardService::SplCardValidationError,
          I18n.t('spl.card_validation.errors.card_not_active')
        )

        user.reload
        expect(user.public_metadata['spl_card_active']).to eq(false)
      end
    end

    context 'when an unexpected error occurs' do
      before { allow(service).to receive(:verify_card_request).and_raise(StandardError, 'boom') }

      it 'restores spl_card_active and persists user' do
        expect { service.call }.to raise_error(StandardError)

        user.reload
        expect(user.public_metadata['spl_card_active']).to eq(false)
      end
    end
  end
end
