# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::LineItemsController, type: :controller do
  let!(:state) { create(:state, country: create(:country_us), name: 'Gdansk', abbr: 'GDA') }
  let(:store) { create(:store) }
  let(:variant) { create(:variant, product: create(:product, stores: [store])) }
  let(:user)  { create(:user, public_metadata: user_metadata) }
  let(:order) { create(:order, user: user, store: store, public_metadata: {}) }
  let(:user_metadata) { {} }

  before do
    allow(controller).to receive(:current_store).and_return(store)
    allow(controller).to receive(:spree_current_user).and_return(user)
    allow(controller).to receive(:spree_current_order).and_return(order)
  end

  describe 'POST #create #add_spl_discount_params_to_order' do
    context 'when user has SPL metadata' do
      let(:user_metadata) { { 'spl_no_card' => '1234567890123', 'spl_card_active' => 'true' } }

      it 'copies SPL metadata into order.public_metadata' do
        post :create, params: { variant_id: variant.id, quantity: 1 }
        order.reload

        expect(order.public_metadata).to include('spl_no_card' => '1234567890123', 'spl_card_active' => true)
      end
    end

    context 'when SPL card is inactive' do
      let(:user_metadata) { { 'spl_no_card' => '1234567890123', 'spl_card_active' => 'false' } }

      it 'casts spl_card_active to boolean false' do
        post :create, params: { variant_id: variant.id, quantity: 1 }
        order.reload

        expect(order.public_metadata['spl_card_active']).to eq(false)
      end
    end

    context 'when user has no SPL metadata' do
      it 'does not modify order.public_metadata' do
        post :create, params: { variant_id: variant.id, quantity: 1 }
        order.reload

        expect(order.public_metadata).to eq({})
      end
    end

    context 'when user is nil' do
      before { allow(controller).to receive(:spree_current_user).and_return(nil) }

      it 'does not raise and does not modify order metadata' do
        expect { post :create, params: { variant_id: variant.id, quantity: 1 } }.not_to raise_error
        order.reload

        expect(order.public_metadata).to eq({})
      end
    end
  end
end
