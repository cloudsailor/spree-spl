# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PromotionSwitcherService do
  let!(:country) { create(:country) }
  let(:store) { create(:store, default_country: country) }
  let(:order) do
    create(
      :order,
      store:,
      public_metadata: public_metadata
    )
  end

  let(:check_only) { true }

  let(:service) { described_class.new(order, check_only) }

  let(:variant1) { create(:variant, sku: 'TESTPRD1', price: 6.75) }
  let(:variant2) { create(:variant, sku: 'TESTPRD4', price: 7.73) }

  let!(:line_item1) { create(:line_item, order:, variant: variant1, quantity: 1, price: 6.75) }
  let!(:line_item2) { create(:line_item, order:, variant: variant2, quantity: 3, price: 7.73) }

  let(:sparta_response) do
    {
      'errorCode' => '0',
      'balanceBurn' => 0.0,
      'balanceEarn' => 0.0,
      'balanceAfter' => 0.12,
      'bookedEarn' => false,
      'processId' => '663c92b05012e0b396ac632b',
      'messages' => [],
      'basket' => [
        {
          'productCode' => 'TESTPRD1',
          'productCode2' => nil,
          'quantity' => 1.0,
          'amountGross' => 6.75,
          'discountGross' => 0.0,
          'discountPercent' => nil,
          'unitPriceGross' => 6.75,
          'discounts' => nil,
          'isAward' => nil,
          'notPromoted' => nil,
          'skipCB' => nil,
          'skipDD' => nil,
          'skipRD' => nil,
          'pos' => 1
        },
        {
          'productCode' => 'TESTPRD4',
          'productCode2' => nil,
          'quantity' => 3.0,
          'amountGross' => 23.2,
          'discountGross' => 0.8,
          'discountPercent' => nil,
          'unitPriceGross' => 7.73,
          'discounts' => [
            {
              'source' => 'LP',
              'amount' => 0.8,
              'percent' => 5.0,
              'code' => '663c926e5012e0b396ac6328',
              'name' => '5% discount for TESTPRD4',
              'order' => 1,
              'quantity' => 2.0,
              'unitPriceGrossDiscounted' => nil
            }
          ],
          'isAward' => nil,
          'notPromoted' => nil,
          'skipCB' => nil,
          'skipDD' => nil,
          'skipRD' => nil,
          'pos' => 2
        }
      ],
      'basketChanged' => true,
      'amountGross' => 29.95,
      'discountGross' => 0.8,
      'coupons' => [],
      'cardType' => { 'code' => 'DV' },
      'requestId' => '00003_LSHRV'
    }
  end

  describe '#call' do
    context 'when spl_card_active is true and card number is present' do
      let(:public_metadata) do
        {
          spl_card_active: 'true',
          spl_no_card: '5100179585157'
        }
      end

      it 'calls Sparta loyalty, gets response and applies Sparta discounts' do
        sparta_service_double = instance_double(Spl::SpartaLoyaltyService)
        apply_service_double  = instance_double(ApplySpartaDiscountService)

        expect(Spl::SpartaLoyaltyService).to receive(:new) do |token, card_no, line_items, date, products, chk, store_arg| # rubocop:disable Layout/LineLength
          expect(token).to eq(order.token)
          expect(card_no).to eq('5100179585157')
          expect(line_items).to match_array(order.line_items)
          expect(date).to be_a(DateTime)
          expect(products).to match_array(order.products)
          expect(chk).to eq(check_only)
          expect(store_arg).to eq(order.store)

          sparta_service_double
        end

        expect(sparta_service_double).to receive(:call).and_return(sparta_response)
        expect(ApplySpartaDiscountService).to receive(:new).with(sparta_response, order)
                                                           .and_return(apply_service_double)
        expect(apply_service_double).to receive(:call)
        expect(order).to receive(:reload).and_call_original

        service.call
      end
    end

    context 'when spl_card_active is true but Sparta returns nil' do
      let(:public_metadata) do
        {
          spl_card_active: true,
          spl_no_card: '5100179585157'
        }
      end

      it 'does not apply Sparta discounts' do
        sparta_service_double = instance_double(Spl::SpartaLoyaltyService)

        expect(Spl::SpartaLoyaltyService).to receive(:new).and_return(sparta_service_double)
        expect(sparta_service_double).to receive(:call).and_return(nil)
        expect(ApplySpartaDiscountService).not_to receive(:new)

        service.call
      end
    end

    context 'when spl_card_active is false' do
      let(:public_metadata) do
        {
          spl_card_active: 'false',
          spl_no_card: '5100179585157'
        }
      end

      it 'removes Sparta discounts' do
        expect(Spl::SpartaLoyaltyService).not_to receive(:new)

        expect(RemoveSpartaDiscountService).to receive(:destroy_all_sparta_adjustments).with(order)

        service.call
      end
    end

    context 'when spl_card_active key is missing' do
      let(:public_metadata) do
        {
          spl_no_card: '5100179585157'
        }
      end

      it 'does nothing' do
        expect(Spl::SpartaLoyaltyService).not_to receive(:new)
        expect(ApplySpartaDiscountService).not_to receive(:new)
        expect(RemoveSpartaDiscountService).not_to receive(:destroy_all_sparta_adjustments)

        service.call
      end
    end

    context 'when there are no line items' do
      let(:public_metadata) do
        {
          spl_card_active: true,
          spl_no_card: '5100179585157'
        }
      end

      before do
        order.line_items.destroy_all
      end

      it 'does not call Sparta loyalty service' do
        expect(Spl::SpartaLoyaltyService).not_to receive(:new)
        expect(ApplySpartaDiscountService).not_to receive(:new)

        service.call
      end
    end

    context 'when card number is missing' do
      let(:public_metadata) do
        {
          spl_card_active: true
        }
      end

      it 'does not call Sparta loyalty service' do
        expect(Spl::SpartaLoyaltyService).not_to receive(:new)
        expect(ApplySpartaDiscountService).not_to receive(:new)

        service.call
      end
    end
  end
end
