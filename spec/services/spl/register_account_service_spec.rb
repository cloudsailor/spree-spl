# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spl::RegisterAccountService do
  subject(:service) { described_class.new(user, store, spl_auth_code) }

  let(:store) do
    create(
      :store,
      default_country: create(:country),
      private_metadata: {
        'spl_url' => 'https://spl.test',
        'spl_prg_code' => 'PRG',
        'spl_partner_code' => 'PARTNER',
        'spl_place_code' => 'PLACE'
      }
    )
  end

  let(:user) do
    create(
      :user,
      phone: '+48500600700',
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@example.com',
      public_metadata: { 'accept_yc_terms' => true }
    )
  end

  let(:spl_auth_code) { '123456' }
  let(:phone_parser) { instance_double(PhoneParserService, country_code: '+48', national_number: '500600700') }
  let(:oauth_response) { { 'response' => { 'accessToken' => 'ACCESS_TOKEN' } } }
  let(:register_response_body) { { 'errorCode' => '0', 'response' => { 'cardNo' => 'CARD123' } } }
  let(:http_response) { instance_double(Net::HTTPResponse, body: register_response_body.to_json) }
  let(:send_request_service) { instance_double(Spl::SendRequestService, call: http_response) }

  before do
    allow(Spl::OauthTokenService).to receive(:new).and_return(
      instance_double(Spl::OauthTokenService, annonymus_token: oauth_response)
    )
    allow(Spl::SendRequestService).to receive(:new).and_return(send_request_service)
  end

  describe '#call' do
    context 'when registration succeeds' do
      xit 'updates user public_metadata with SPL card data' do
        service.call

        expect(user.public_metadata).to include(
          'spl_no_card' => 'CARD123',
          'spl_card_active' => true,
          'mobile_country' => '+48',
          'phone_number' => '500600700'
        )
      end

      xit 'sends correct payload to SendRequestService' do
        expect(Spl::SendRequestService).to receive(:new) do |url, body|
          expect(url.to_s).to include('register')
          expect(body).to include(authCode: spl_auth_code, partnerCode: 'PARTNER', placeCode: 'PLACE')
          expect(body[:context]).to include(oauthToken: 'ACCESS_TOKEN', prgCode: 'PRG')
          expect(body[:person][:permissions]).to eq(processData: true, operationalSms: true)
          expect(body[:person]).to include(
            firstName: 'John',
            lastName: 'Doe',
            email: 'john@example.com',
            mobileCountry: '+48',
            mobile: '500600700'
          )
        end.and_return(send_request_service)

        service.call
      end
    end

    context 'when SPL returns errorCode != 0' do
      let(:register_response_body) { { 'errorCode' => 'TEMPORARY_BLOCKED', 'msg' => 'Temporarily blocked' } }

      xit 'raises SplRegisterAccountError with SPL message' do
        expect do
          service.call
        end.to raise_error(Spl::RegisterAccountService::SplRegisterAccountError, 'Temporarily blocked')
      end

      xit 'does not update user public_metadata' do
        expect do
          service.call
        rescue StandardError
          nil
        end.not_to(change { user.reload.public_metadata })
      end
    end

    context 'when OTP code is not 6 characters' do
      let(:spl_auth_code) { '123' }

      xit 'still sends request to SPL (no local validation)' do
        expect(Spl::SendRequestService).to receive(:new).and_return(send_request_service)

        service.call
      end
    end

    context 'when card number is provided and phone is nil' do
      before do
        user.update!(phone: nil, public_metadata: user.public_metadata.merge('spl_no_card' => 'CARD123'))
        allow(PhoneParserService).to receive(:new).with(nil).and_raise(StandardError, 'Phone missing')
      end

      xit 'raises error before sending request' do
        expect { service.call }.to raise_error(StandardError, 'Phone missing')
      end

      xit 'does not send request to SPL' do
        expect(Spl::SendRequestService).not_to receive(:new)
        expect { service.call }.to raise_error(StandardError)
      end
    end
  end
end
