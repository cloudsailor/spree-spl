# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spl::Coupons::GetCouponsService do
  let(:user)  { create(:user, private_metadata: { 'spl_access_token' => 'LPUXLUZYZ9JN8XLXSSCTZA4Y5LEFEX' }) }
  let(:store) { Spree::Store.default }
  let(:service) { described_class.new(user, store) }
  let(:request_url) do
    URI.parse(Spl::UrlCreatorService.new(store.private_metadata['spl_url']).coupon_find)
  end
  let(:prepared_body) do
    {
      context: {
        prgCode: 'prg-2',
        oauthToken: 'LPUXLUZYZ9JN8XLXSSCTZA4Y5LEFEX' # real exammple token
      },
      withArchival: true
    }
  end
  let(:request_service) { instance_double(Spl::SendRequestService) }
  let(:response_double) { instance_double(Net::HTTPResponse) }

  before do
    store.update(private_metadata: { 'spl_url' => 'https://example.com', 'spl_prg_code' => 'prg-2' })
    allow(Spl::SendRequestService).to receive(:new)
      .with(request_url, prepared_body)
      .and_return(request_service)
    allow(request_service).to receive(:call).and_return(response_double)
  end

  describe '#call' do
    context 'when service returns valid coupons' do
      let(:valid_response_body) do
        {
          'errorCode' => '0',
          'validationMessages' => nil,
          'fieldValidationMessages' => nil,
          'response' => [
            {
              'code' => '9004850879237',
              'expirationDate' => nil,
              'valid' => true,
              'type' => '90_CRAZY',
              'typeId' => '67583a525012cbcf734c281a',
              'typeCustomerName' => '90% CRAZY KUPON',
              'typeCustomerDescription' => 'YOLO 90% NA WSZYSTKO',
              'typeCustomerShortDescription' => nil,
              'image' => '06FBC68FD78D56077B86720C9C22A9158FE35184.jpg',
              'imageUrl' => 'https://demo.spartaloyalty.com/TestYes/binary/img/06FBC68FD78D56077B86720C9C22A9158FE35184.jpg',
              'images' => nil,
              'imagesUrl' => nil,
              'relatedUrl' => nil,
              'autoLoad' => nil,
              'couponType' => {
                'autoLoad' => 'A',
                'transferDisabled' => nil,
                'visualizationType' => nil
              },
              'used' => false,
              'balance' => nil,
              'usageDisabled' => nil,
              'usageTemporaryBlocked' => false,
              'productCode' => nil,
              'productPartnerCode' => nil,
              'kind' => nil,
              'qrCode' => nil,
              'issuedTransactionId' => nil
            }
          ],
          'msg' => 'OK'
        }
      end

      before do
        allow(response_double).to receive(:body).and_return(valid_response_body.to_json)
      end

      it 'returns the coupons array' do
        expect(service.call).to eq(valid_response_body['response'])
      end
    end

    context 'when service returns empty coupons array' do
      let(:empty_response_body) do
        {
          'errorCode' => '0',
          'validationMessages' => nil,
          'fieldValidationMessages' => nil,
          'response' => [],
          'msg' => 'OK'
        }
      end

      before do
        allow(response_double).to receive(:body).and_return(empty_response_body.to_json)
      end

      it 'returns an empty array' do
        expect(service.call).to eq([])
      end
    end

    context 'when service returns an error' do
      let(:error_response_body) do
        { 'errorCode' => 'TOKEN_EXPIRED', 'validationMessages' => nil, 'fieldValidationMessages' => nil,
          'response' => nil, 'msg' => 'Token expired' }
      end

      before do
        allow(response_double).to receive(:body).and_return(error_response_body.to_json)
        service.instance_variable_set(:@retry_counter, 0)
      end

      it 'raises SplGetCouponError with message' do
        expect { service.call }.to raise_error(
          Spl::Coupons::GetCouponsService::SplGetCouponError,
          'Token expired'
        )
      end
    end

    context 'when user is not logged-in ' do
      let(:user)  { create(:user, private_metadata: nil) }

      it 'does nothing' do
        expect(service.call).to eq(nil)
      end
    end

    it 'sends a request with the correct body and URL' do
      allow(response_double).to receive(:body).and_return({ 'errorCode' => '0', 'response' => [] }.to_json)
      service.call
      expect(Spl::SendRequestService).to have_received(:new).with(request_url, prepared_body)
      expect(request_service).to have_received(:call)
    end
  end
end
