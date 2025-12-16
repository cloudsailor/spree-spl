# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Account::ProfileController, type: :controller do
  before do
    unless defined?(Spl::SendOtpService::SplSendOtpError)
      stub_const('Spl::SendOtpService::SplSendOtpError', Class.new(StandardError))
    end
  end

  let(:store) { instance_double(Spree::Store) }
  let!(:user) { create(:user, public_metadata: {}) }

  let(:terms_accepted) { 'true' }
  let(:phone_valid) { true }
  let(:phone_value) { '+48500600700' }

  let(:phone_double) do
    instance_double(
      'PhoneParserService',
      valid?: phone_valid,
      country_code: '+48',
      national_number: '500600700',
      e164: '+48500600700'
    )
  end

  let(:turbo_stream_helper) { instance_double('TurboStreamHelper') }

  before do
    allow(controller).to receive(:current_store).and_return(store)
    allow(controller).to receive(:try_spree_current_user).and_return(user)
    allow(controller).to receive(:login_code_params).and_return(
      ActionController::Parameters.new(phone: phone_value, accept_yc_terms: terms_accepted).permit!
    )
    allow(controller).to receive(:phone_parser).and_return(phone_double)
    allow(controller).to receive(:turbo_stream).and_return(turbo_stream_helper)
    allow(turbo_stream_helper).to receive(:replace).and_return('<turbo-stream></turbo-stream>')

    user.errors.clear
  end

  describe '#validate_login_code_request (before_action logic)' do
    context 'when YC terms are not accepted' do
      let(:terms_accepted) { 'false' }

      it 'adds error and renders 422 (does not touch OTP service)' do
        expect(Spl::SendOtpService).not_to receive(:new)
        expect(controller).to receive(:render).with(hash_including(status: :unprocessable_entity))
        controller.send(:validate_login_code_request)
        expect(user.errors.full_messages.join(' ')).to include(I18n.t('spl.user.errors.must_accept_yc_terms'))
      end
    end

    context 'when phone is invalid' do
      let(:phone_valid) { false }

      it 'adds phone error and renders 422 (does not touch OTP service)' do
        expect(Spl::SendOtpService).not_to receive(:new)
        expect(controller).to receive(:render).with(hash_including(status: :unprocessable_entity))
        controller.send(:validate_login_code_request)
        expect(user.errors.full_messages.join(' ')).to include(I18n.t('spl.user.errors.invalid_phone'))
      end
    end

    context 'when everything is valid' do
      it 'does not render and does not add errors' do
        expect(controller).not_to receive(:render)
        controller.send(:validate_login_code_request)
        expect(user.errors).to be_empty
      end
    end
  end

  describe '#login_code (service + success/rescue)' do
    context 'when OTP service raises SplSendOtpError' do
      it 'renders 422 and shows service message as base error' do
        service_instance = instance_double('Spl::SendOtpService')

        expect(Spl::SendOtpService).to receive(:new)
          .with(kind_of(DateTime), '+48', '500600700', store)
          .and_return(service_instance)
        expect(service_instance).to receive(:call)
          .and_raise(Spl::SendOtpService::SplSendOtpError.new('Person not found'))
        expect(controller).to receive(:render).with(hash_including(status: :unprocessable_entity))
        controller.login_code
        expect(user.errors.full_messages.join(' ')).to include('Person not found')
      end
    end

    context 'when OTP is sent successfully' do
      it 'calls OTP service, updates accept_yc_terms in public_metadata, and renders 200' do
        service_instance = instance_double('Spl::SendOtpService')

        expect(Spl::SendOtpService).to receive(:new)
          .with(kind_of(DateTime), '+48', '500600700', store)
          .and_return(service_instance)
        expect(service_instance).to receive(:call)
        expect(controller).to receive(:render).with(hash_including(status: :ok))
        controller.login_code
        expect(user.reload.public_metadata['accept_yc_terms']).to eq(true)
      end
    end
  end
end
