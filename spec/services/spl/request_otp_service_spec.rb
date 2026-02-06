# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spl::RequestOtpService do
  subject(:service) { described_class.new(date, store, params) }

  let(:store) do
    create(:store, default_country: create(:country), private_metadata: {
             'spl_url' => 'https://spl.test',
             'spl_prg_code' => 'PRG'
           })
  end

  let(:date) { DateTime.current }
  let(:oauth_response) { { 'response' => { 'accessToken' => 'ACCESS_TOKEN' } } }
  let(:success_response_body) { { 'errorCode' => '0', 'response' => { 'status' => 'OK' } } }
  let(:error_response_body) { { 'errorCode' => 'TEMPORARY_BLOCKED', 'msg' => 'Temporarily blocked' } }
  let(:response_body) { success_response_body }
  let(:http_response) { instance_double(Net::HTTPResponse, body: response_body.to_json) }

  let(:send_request_service) { instance_double(Spl::SendRequestService, call: http_response) }

  before do
    allow(Spl::OauthTokenService).to receive(:new).and_return(
      instance_double(Spl::OauthTokenService, annonymus_token: oauth_response)
    )
    allow(Spl::SendRequestService).to receive(:new).and_return(send_request_service)
  end

  describe '#call' do
    context 'when requesting OTP via SMS' do
      let(:params) { { mobile_country: '+48', phone_number: '500600700' } }

      it 'returns parsed response body' do
        expect(service.call).to eq(success_response_body)
      end

      it 'sends correct SMS payload to SendRequestService' do
        expect(Spl::SendRequestService).to receive(:new) do |url, body|
          expect(url.to_s).to include('requestOTP')
          expect(body).to include(channel: 'S', mobileCountry: '+48', mobile: '500600700')
          expect(body[:context]).to include(oauthToken: 'ACCESS_TOKEN', prgCode: 'PRG')
        end.and_return(send_request_service)

        service.call
      end
    end

    context 'when requesting OTP via email' do
      let(:params) { { email: 'test@example.com' } }

      it 'sends email OTP payload' do
        expect(Spl::SendRequestService).to receive(:new) do |_url, body|
          expect(body).to include(channel: 'E', email: 'test@example.com')
        end.and_return(send_request_service)

        service.call
      end
    end

    context 'when SPL returns errorCode != 0' do
      let(:params) { { mobile_country: '+48', phone_number: '500600700' } }
      let(:response_body) { error_response_body }

      it 'raises SplRequestOtpError with SPL message' do
        expect do
          service.call
        end.to raise_error(Spl::RequestOtpService::SplRequestOtpError, error_response_body.to_s)

      end
    end
  end
end
