# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spl::SendOtpService, type: :service do
  let(:store) do
    instance_double(
      Spree::Store,
      private_metadata: { 'spl_url' => 'https://spl.test' }
    )
  end

  let(:env) do
    {
      'spl_prg_code' => 'PRG',
      'spl_api_user' => 'user',
      'spl_api_token' => 'token',
      'spl_signature_seed' => 'seed'
    }
  end

  let(:date) { DateTime.parse('2025-12-16 12:00:00 UTC') }
  let(:date_ms) { date.to_i * 1000 }
  let(:mobile_country) { '+48' }
  let(:phone_number) { '500600700' }
  let(:send_otp_url) { 'https://spl.test/api/send-otp' }
  let(:uri) { URI.parse(send_otp_url) }
  let(:signature) { 'computed-signature' }
  let(:url_creator) { instance_double('Spl::UrlCreatorService', send_otp: send_otp_url) }
  let(:signature_service) { instance_double('Spl::ClientSignatureService', call: signature) }
  let(:http_response) { instance_double('Net::HTTPResponse', body: response_body_json) }

  before do
    allow(Spl::StorePrivateMetadataService).to receive(:all).with(store).and_return(env)
    allow(Spl::UrlCreatorService).to receive(:new).with('https://spl.test').and_return(url_creator)
    allow(Spl::ClientSignatureService).to receive(:new)
      .with(date_ms, env['spl_api_token'], env['spl_signature_seed'])
      .and_return(signature_service)
    allow(Spl::SendRequestService).to receive(:new)
      .and_return(instance_double('Spl::SendRequestService', call: http_response))
    allow(Rails.logger).to receive(:debug)
  end

  subject(:service) { described_class.new(date, mobile_country, phone_number, store) }

  describe '#call' do
    context "when API returns success (errorCode == '0')" do
      let(:response_body_json) { { 'errorCode' => '0', 'msg' => nil, 'response' => { 'ok' => true } }.to_json }

      it 'returns parsed response hash' do
        result = service.call
        expect(result).to be_a(Hash)
        expect(result['errorCode']).to eq('0')
        expect(result['response']).to eq({ 'ok' => true })
      end

      it 'sends request with correct url and body' do
        expected_body = {
          context: { prgCode: 'PRG' },
          apiUser: 'user',
          apiToken: 'token',
          signatureSeed: 'seed',
          date: date_ms,
          mobileCountry: '+48',
          mobile: '500600700',
          signature: signature
        }

        expect(Spl::SendRequestService).to receive(:new) do |passed_url, passed_body|
          expect(passed_url).to eq(uri)
          expect(passed_body).to eq(expected_body)
        end.and_return(instance_double('Spl::SendRequestService', call: http_response))

        service.call
      end
    end

    context "when API returns an error (errorCode != '0')" do
      let(:response_body_json) { { 'errorCode' => 'PERSON_NOT_FOUND', 'msg' => 'Person not found' }.to_json }

      it 'raises SplSendOtpError with msg' do
        expect { service.call }
          .to raise_error(Spl::SendOtpService::SplSendOtpError, /Person not found/)
      end
    end

    context 'when API returns errorCode but msg is missing' do
      let(:response_body_json) { { 'errorCode' => 'SOMETHING_BAD' }.to_json }

      it 'raises SplSendOtpError (message can be nil/blank depending on payload)' do
        expect { service.call }.to raise_error(Spl::SendOtpService::SplSendOtpError)
      end
    end
  end
end
