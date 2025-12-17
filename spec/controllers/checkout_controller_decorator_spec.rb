# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::CheckoutController, type: :controller do
  describe '#load_user_coupons' do
    let!(:order)   { create(:order) }
    let!(:service) { instance_double(Spl::GetCouponsService) }

    before do
      allow(controller).to receive(:order).and_return(order)
      controller.instance_variable_set(:@order, order)
      allow(Spl::GetCouponsService).to receive(:new)
        .with(order.user, order.store)
        .and_return(service)
    end

    subject(:load_user_coupons) { controller.send(:load_user_coupons) }

    context 'when the service returns coupons' do
      let(:coupons) { %w[COUP1 COUP2] }

      before { allow(service).to receive(:call).and_return(coupons) }

      it 'sets @coupons' do
        load_user_coupons
        expect(assigns(:coupons)).to eq(coupons)
      end
    end

    context 'when the service returns an empty array' do
      before { allow(service).to receive(:call).and_return([]) }

      it 'sets @coupons to an empty array' do
        load_user_coupons
        expect(assigns(:coupons)).to eq([])
      end
    end

    context 'when the service raises an error' do
      before { allow(service).to receive(:call).and_raise(StandardError.new('fail')) }

      it 'propagates the error' do
        expect { load_user_coupons }.to raise_error(StandardError, 'fail')
      end
    end
  end
end
