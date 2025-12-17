# spec/controllers/checkout_controller_decorator_spec.rb
require 'rails_helper'

RSpec.describe Spree::CheckoutController, type: :controller do
  routes { Spree::Core::Engine.routes }

  describe 'load_user_coupons before_action' do
    let(:order)   { create(:order) }
    let(:service) { instance_double(Spl::GetCouponsService) }
    let(:coupons) { %w[COUP1 COUP2] }

    before do
      Spree::CheckoutController.prepend(Spl::Spree::Storefront::CheckoutControllerDecorator)
      allow(controller).to receive(:order).and_return(order)
      controller.instance_variable_set(:@order, order)

      allow(Spl::GetCouponsService).to receive(:new)
                                         .with(order.user, order.store)
                                         .and_return(service)

      allow(service).to receive(:call).and_return(coupons)
    end

    it 'sets @coupons' do
      #
      # Spree 5 checkout requires BOTH :token and :state
      #
      get :edit,
          params: {
            token: 'asdasd', # REQUIRED
            state: "address"          # REQUIRED
          },
          format: :json

      expect(assigns(:coupons)).to eq(coupons)
    end
  end
end
