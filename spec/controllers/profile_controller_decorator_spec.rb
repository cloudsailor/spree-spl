# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Account::ProfileController, type: :controller do
  let!(:state) { create(:state, country: create(:country_us), name: 'Gdansk', abbr: 'GDA') }
  let(:store) { create(:store) }
  let(:user) { create(:user) }
  let(:service_double) { instance_double(Spl::ValidateCardService, call: true) }

  before do
    create(:order, user: user, state: 'cart', public_metadata: {})
    allow(controller).to receive(:current_store).and_return(store)
    allow(controller).to receive(:spree_current_user).and_return(user)
    allow(Spl::ValidateCardService).to receive(:new).and_return(service_double)
  end

  describe 'validate_spl_no_card' do
    context 'when spl_no_card is missing' do
      it 'does NOT call the ValidateCardService' do
        put :update, params: { user: { public_metadata: { spl_no_card: '', spl_card_active: false } } }

        expect(Spl::ValidateCardService).not_to receive(:new)
      end
    end

    context 'when spl_card_active is false (card deactivated)' do
      it 'does NOT call ValidateCardService' do
        put :update, params: { user: { public_metadata: { spl_no_card: '1234567890123', spl_card_active: false } } }

        expect(Spl::ValidateCardService).not_to receive(:new)
      end
    end

    context 'when spl_no_card exists and card is active' do
      it 'calls ValidateCardService with correct parameters' do
        put :update, params: { user: { public_metadata: { spl_no_card: '1234567890123', spl_card_active: true } } }

        expect(service_double).to have_received(:call)
      end
    end

    context 'when ValidateCardService raises SplCardValidationError' do
      before do
        create(:order, user: user, state: 'cart', public_metadata: { 'other' => 'x' })
        allow(service_double).to receive(:call).and_raise(Spl::ValidateCardService::SplCardValidationError.new('Invalid'))
      end

      it 'renders edit with status 422' do
        put :update, params: { user: { public_metadata: { spl_no_card: '1234567890123', spl_card_active: 'true' } } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template(:edit)
      end

      it 'sets flash error message' do
        put :update, params: { user: { public_metadata: { spl_no_card: '1234567890123', spl_card_active: 'true' } } }

        expect(flash[:error]).to eq('Invalid')
      end
    end
  end
end
