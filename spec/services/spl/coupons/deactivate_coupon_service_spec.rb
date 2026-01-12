# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spl::Coupons::DeactivateCouponService do
  subject(:service) { described_class.new(user, store, params) }

  let(:user)  { create(:user) }
  let(:store) { Spree::Store.default }

  let(:spl_url)      { 'https://spl.example.test' }
  let(:prg_code)     { 'prg2' }
  let(:access_token) { 'LPUXLUZYZ9JN8XLXSSCTZA4Y5LEFEX' }

  let(:coupon_code) { 'COUPON' }
  let(:params) { coupon_code }

  let(:deactivate_url_string) { 'https://api.spl.example.test/coupons/deactivate' }
  let(:deactivate_uri) { URI.parse(deactivate_url_string) }

  let(:success_body_raw) do
    {
      'errorCode' => '0',
      'validationMessages' => nil,
      'fieldValidationMessages' => nil,
      'response' => { 'returned' => nil },
      'msg' => 'OK'
    }.to_json
  end

  let(:response) { instance_double('Net::HTTPResponse', body: success_body_raw) }

  before do
    allow(store).to receive(:private_metadata).and_return(
      'spl_url' => spl_url,
      'spl_prg_code' => prg_code
    )
    allow(user).to receive(:private_metadata).and_return(
      'spl_access_token' => access_token
    )

    url_creator = instance_double('Spl::UrlCreatorService', coupon_deactivate: deactivate_url_string)
    allow(Spl::UrlCreatorService).to receive(:new).with(spl_url).and_return(url_creator)

    allow(service).to receive(:send_request).and_return(response)
  end

  describe '#call' do
    context "success (errorCode == '0')" do
      it "sends request to coupon_deactivate URI with expected body and returns parsed 'response' hash" do
        expected_body = {
          context: {
            prgCode: prg_code,
            oauthToken: access_token
          },
          couponCode: coupon_code
        }

        expect(service).to receive(:send_request).with(deactivate_uri, expected_body).and_return(response)

        expect(service.call).to eq({ 'returned' => nil })
      end

      it "succeeds even if validation messages are present (still errorCode '0')" do
        body = {
          'errorCode' => '0',
          'validationMessages' => ['some warning'],
          'fieldValidationMessages' => { 'couponCode' => ['format warning'] },
          'response' => { 'returned' => nil },
          'msg' => 'OK'
        }.to_json

        allow(service).to receive(:send_request).and_return(instance_double('Net::HTTPResponse', body: body))

        expect(service.call).to eq({ 'returned' => nil })
      end

      it "returns nil if 'response' key is missing" do
        body = { 'errorCode' => '0', 'msg' => 'OK' }.to_json
        allow(service).to receive(:send_request).and_return(instance_double('Net::HTTPResponse', body: body))

        expect(service.call).to be_nil
      end

      it "returns nil if 'response' is null" do
        body = { 'errorCode' => '0', 'response' => nil, 'msg' => 'OK' }.to_json
        allow(service).to receive(:send_request).and_return(instance_double('Net::HTTPResponse', body: body))

        expect(service.call).to be_nil
      end
    end

    context "API failure (errorCode != '0')" do
      it 'raises DeactivateCouponServiceError with msg' do
        body = { 'errorCode' => 'COUPON_CANNOT_BE_MODIFIED', 'msg' => 'Coupon invalid', 'response' => nil }.to_json
        allow(service).to receive(:send_request).and_return(instance_double('Net::HTTPResponse', body: body))

        expect { service.call }
          .to raise_error(described_class::DeactivateCouponServiceError, 'Coupon invalid')
      end

      it 'raises even if msg is missing' do
        body = { 'errorCode' => 'COUPON_CANNOT_BE_MODIFIED' }.to_json
        allow(service).to receive(:send_request).and_return(instance_double('Net::HTTPResponse', body: body))

        expect { service.call }.to raise_error(described_class::DeactivateCouponServiceError)
      end
    end

    context 'bad/empty HTTP response' do
      it 'raises JSON::ParserError for invalid JSON' do
        allow(service).to receive(:send_request).and_return(instance_double('Net::HTTPResponse', body: 'not-json'))
        expect { service.call }.to raise_error(JSON::ParserError)
      end

      it 'raises TypeError when response.body is nil (JSON.parse(nil))' do
        allow(service).to receive(:send_request).and_return(instance_double('Net::HTTPResponse', body: nil))
        expect { service.call }.to raise_error(TypeError)
      end

      it 'raises NoMethodError when send_request returns nil (nil.body)' do
        allow(service).to receive(:send_request).and_return(nil)
        expect { service.call }.to raise_error(NoMethodError)
      end

      it 'bubbles exceptions from send_request (e.g., timeouts)' do
        allow(service).to receive(:send_request).and_raise(Timeout::Error)
        expect { service.call }.to raise_error(Timeout::Error)
      end
    end
  end
end
