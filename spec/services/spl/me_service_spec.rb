# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spl::MeService, type: :service do
  subject(:service) { described_class.new(user, store) }

  let(:country) { create(:country) }
  let(:user) { create(:user, private_metadata: { 'spl_access_token' => 'access-token-123' }) }
  let(:store) { create(:store, default_country: country, private_metadata: { 'spl_url' => 'https://api.example.test' }) }
  let(:env) { { 'spl_prg_code' => 'PRG001' } }
  let(:me_url) { 'https://api.example.test/me' }

  before do
    allow(Spl::StorePrivateMetadataService).to receive(:all).with(store).and_return(env)

    url_creator = instance_double(Spl::UrlCreatorService, me: me_url)
    allow(Spl::UrlCreatorService).to receive(:new).with('https://api.example.test').and_return(url_creator)
  end

  describe '#call' do
    context "when API returns success (errorCode == '0')" do
      let(:expected_body) do
        {
          context: {
            prgCode: 'PRG001',
            oauthToken: 'access-token-123'
          }
        }
      end
      let(:success_response_hash) do
        { 'errorCode' => '0', 'data' => { 'foo' => 'bar' } }
      end

      it 'sends request with correct body and returns parsed response body' do
        response = double('Response', body: success_response_hash.to_json)
        request_service = instance_double(Spl::SendRequestService)

        expect(Spl::SendRequestService).to receive(:new)
          .with(URI.parse(me_url), expected_body)
          .and_return(request_service)
        expect(request_service).to receive(:call).and_return(response)
        expect(service.call).to eq(success_response_hash)
      end
    end

    context "when API returns an error (errorCode != '0')" do
      let(:error_response_hash) do
        {
          'errorCode' => 'TEMPORARY_BLOCKED',
          'msg' => 'Temporarily blocked'
        }
      end

      before do
        response = double('Response', body: error_response_hash.to_json)
        request_service = instance_double(Spl::SendRequestService)
        allow(Spl::SendRequestService).to receive(:new).and_return(request_service)
        allow(request_service).to receive(:call).and_return(response)
      end

      it 'raises SplMeError' do
        expect { service.call }
          .to raise_error(Spl::MeService::SplMeError, error_response_hash.to_s)
      end
    end
  end
end
