# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Payment, type: :model do
  let(:store) { Spree::Store.default || create(:store, default: true) }

  let(:order) { create(:order, store: store) }

  subject(:payment) { described_class.new(order: order) }

  describe '#promotion_switcher (private)' do
    let(:service_result) { :some_result }
    let(:service_instance) { instance_double(PromotionSwitcherService, call: service_result) }

    it 'initializes PromotionSwitcherService with order + check_only and calls it' do
      allow(PromotionSwitcherService).to receive(:new).and_return(service_instance)

      result = payment.send(:promotion_switcher, order, true)

      expect(PromotionSwitcherService).to have_received(:new).with(order, true)
      expect(service_instance).to have_received(:call)
      expect(result).to eq(service_result)
    end

    it 'passes false correctly as check_only flag' do
      allow(PromotionSwitcherService).to receive(:new).and_return(service_instance)

      payment.send(:promotion_switcher, order, false)

      expect(PromotionSwitcherService).to have_received(:new).with(order, false)
    end
  end

  describe '#preform_update_sparta_state_job (private)' do
    it "enqueues UpdateSpartaStateJob with token, state 'D', number, store" do
      allow(UpdateSpartaStateJob).to receive(:perform_later)

      payment.send(:preform_update_sparta_state_job)

      expect(UpdateSpartaStateJob).to have_received(:perform_later).with(
        order.token,
        'D',
        order.number,
        order.store
      )
    end
  end
end
