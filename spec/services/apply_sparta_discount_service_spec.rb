# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplySpartaDiscountService do
  let(:country) { create(:country) }
  let(:store)    { create(:store, default_country: country) }
  let(:order)    { create(:order, store: store) }

  let(:variant1) { create(:variant, price: 6.75,  sku: 'BS49252-BZ020-PSA000-000') }
  let(:variant2) { create(:variant, price: 7.73,  sku: 'BS49252-BZ020-PSA000-001') }

  let!(:line_item1) { create(:line_item, order: order, variant: variant1, quantity: 1, price: 6.75) }
  let!(:line_item2) { create(:line_item, order: order, variant: variant2, quantity: 3, price: 7.73) }

  let(:base_response) do
    {
      'errorCode' => '0',
      'response' => {
        'basket' => sparta_basket
      }
    }
  end

  let(:sparta_basket) do
    [
      {
        'productCode' => 'TESTPRD1',
        'quantity' => 1.0,
        'amountGross' => 6.75,
        'discountGross' => 0.0,
        'discounts' => nil,
        'pos' => line_item1.id
      },
      {
        'productCode' => 'TESTPRD4',
        'quantity' => 3.0,
        'amountGross' => 23.2,
        'discountGross' => 0.8,
        'discounts' => [
          {
            'name' => '5% discount for TESTPRD4',
            'amount' => 0.8
          }
        ],
        'pos' => line_item2.id
      }
    ]
  end

  let(:service) { described_class.new(base_response, order) }

  before do
    allow(RemoveSpartaDiscountService).to receive(:destroy_inactive_adjustments)
    allow(Spree::Dependencies).to receive(:cart_recalculate_service).and_return('FakeCartRecalculateService')
    stub_const('FakeCartRecalculateService', Class.new do
      def self.call(order:, line_item: nil); end
    end)
  end

  describe '#call' do
    it 'creates SPL adjustment for discounted items' do
      service.call

      adj = line_item2.adjustments.find_by(source_type: 'SPL')

      expect(adj).not_to be_nil
      expect(adj.amount).to eq(-0.8)
      expect(adj.label).to eq("SPARTA_5% discount for TESTPRD4_#{line_item2.id}")
    end

    it 'does NOT create adjustment for items with no discounts' do
      service.call

      expect(line_item1.adjustments.where(source_type: 'SPL')).to be_empty
    end

    it 'removes non-SPL promotion adjustments before creating SPL discount' do
      line_item2.adjustments.create!(
        source_type: 'Promotion',
        amount: -5,
        label: 'OLD_PROMO',
        order: order
      )

      expect do
        service.call
      end.to change { line_item2.adjustments.where(source_type: 'SPL').count }.by(1)
      expect(line_item2.adjustments.where(label: 'OLD_PROMO')).to be_empty
    end

    it 'updates existing SPL adjustment instead of creating a new one' do
      existing = line_item2.adjustments.create!(
        source_type: 'SPL',
        amount: -0.5,
        label: "SPARTA_5% discount for TESTPRD4_#{line_item2.id}",
        order: order
      )

      service.call

      existing.reload
      expect(existing.amount).to eq(-0.8)
      expect(line_item2.adjustments.where(source_type: 'SPL').count).to eq(1)
    end

    it 'removes SPL adjustments if Sparta discount becomes nil' do
      line_item2.adjustments.create!(
        source_type: 'SPL',
        amount: -0.8,
        label: "SPARTA_5% discount for TESTPRD4_#{line_item2.id}",
        order: order
      )

      sparta_basket[1]['discounts'] = nil
      sparta_basket[1]['discountGross'] = 0.0
      expect(RemoveSpartaDiscountService).to receive(:destroy_inactive_adjustments)

      service.call
    end

    it 'does nothing when errorCode != 0' do
      base_response['errorCode'] = '123'

      expect(line_item2.adjustments).to be_empty

      service.call

      expect(line_item2.adjustments).to be_empty
    end

    it "does nothing when response['basket'] is missing" do
      base_response['response']['basket'] = nil

      service.call

      expect(line_item2.adjustments).to be_empty
    end
  end
end
