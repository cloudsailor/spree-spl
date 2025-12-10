# frozen_string_literal: true

require 'rails_helper'

describe Spree::CheckoutController, type: :controller do
  let(:store) do
    create(:store, private_metadata: {
             'spl_url' => 'https://fake-spl.example.com',
             'spl_mode' => 'test',
             'spl_pos_key' => 'fake-pos-key',
             'spl_api_user' => 'fake-api-user',
             'spl_prg_code' => 'fake-prg-code',
             'spl_sale_url' => 'https://fake-spl.example.com/sale',
             'spl_api_token' => 'fake-token',
             'spl_place_code' => 'fake-place',
             'spl_partner_code' => 'fake-partner',
             'spl_signature_seed' => 'fake-seed'
           })
  end

  let!(:state) { create(:state, country: create(:country_us), name: 'Gdansk', abbr: 'GDA') }
  let(:user) { create(:user, public_metadata: { 'spl_no_card' => 'fake-no-card', 'spl_card_active' => 'true' }) }

  let(:order) do
    create(
      :order_with_totals,
      store: store,
      user: user,
      email: 'test@example.com',
      public_metadata: {
        'spl_no_card' => 'fake-no-card',
        'spl_card_active' => 'true'
      }
    )
  end

  before do
    allow(controller).to receive_messages(current_store: store, try_spree_current_user: user, spree_current_user: user,
                                          spree_signup_path: '/signup', spree_login_path: '/login')

    stub_request(:any, /fake-spl\.example\.com/).to_return(
      status: 200,
      body: {
        'errorCode' => '0',
        'response' => {
          'basket' => order.line_items.map do |li|
            {
              'pos' => li.id,
              'discounts' => [
                {
                  'name' => 'TEST'
                }
              ],
              'discountGross' => 5.0
            }
          end
        }
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    allow_any_instance_of(Spree::Order).to receive(:recalculate).and_return(true)
  end

  describe '#promotion_switcher' do
    context 'creates a new SPL adjustment' do
      it 'with SPL source_type' do
        post :update, params: { state: 'address', token: order.token }

        expect(order.line_items.last.adjustments.last.source_type).to eq('SPL')
      end

      it 'with amount from discountGross' do
        post :update, params: { state: 'address', token: order.token }

        expect(order.line_items.last.adjustments.last.amount).to eq(-5.0)
      end
    end
  end
end
