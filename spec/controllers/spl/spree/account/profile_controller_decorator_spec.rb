# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spree::Account::ProfileController, type: :controller do
  before do
    unless defined?(Spl::SendOtpService::SplSendOtpError)
      stub_const('Spl::SendOtpService::SplSendOtpError', Class.new(StandardError))
    end
  end

  let(:country) { create(:country) }
  let(:store) { create(:store, default_country: country) }
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
    allow(Spree::Spl).to receive(:report_error).and_return(nil)
    user.errors.clear
  end

  describe '#registration_code (service + success/rescue)' do
    before do
      allow(controller).to receive(:login_code_params).and_return(
        ActionController::Parameters.new(phone: phone_value, accept_yc_terms: terms_accepted).permit!
      )
    end

    context 'when OTP request succeeds' do
      xit 'calls RequestOtpService, updates user, and renders 200' do
        service_instance = instance_double(Spl::RequestOtpService)

        expect(Spl::RequestOtpService).to receive(:new)
          .with(kind_of(DateTime), '+48', '500600700', store)
          .and_return(service_instance)

        expect(service_instance).to receive(:call)
        expect(controller).to receive(:render).with(hash_including(status: :ok))

        controller.registration_code

        expect(user.reload.phone).to eq(phone_value)
        expect(user.public_metadata['accept_yc_terms']).to eq(true)
      end
    end

    shared_examples 'registration_code error' do |error_class|
      xit "renders 422 and adds translated base error for #{error_class}" do
        payload = {
          'errorCode' => 'TEMPORARY_BLOCKED',
          'msg' => 'Temporarily blocked'
        }

        service_instance = instance_double(Spl::RequestOtpService)

        allow(Spl::RequestOtpService).to receive(:new).and_return(service_instance)
        allow(service_instance).to receive(:call).and_raise(error_class.new(payload.inspect))

        expect(controller).to receive(:render).with(hash_including(status: :unprocessable_entity))

        controller.registration_code

        expect(user.errors.full_messages.join(' ')).to include(I18n.t('spl.errors.temporary_blocked'))
      end
    end

    context 'when RequestOtpService raises error' do
      include_examples 'registration_code error', Spl::RequestOtpService::SplRequestOtpError
    end

    context 'when OauthTokenService raises error' do
      include_examples 'registration_code error', Spl::OauthTokenService::OauthTokenError
    end
  end

  describe '#register_loyalty_account (service + success/rescue)' do
    let(:params_hash) { { 'user' => { 'spl_auth_code' => '123456' } } }

    before do
      allow(controller).to receive(:params).and_return(params_hash)
      allow(controller).to receive(:spree_current_user).and_return(user)
    end

    context 'when registration succeeds' do
      xit 'calls RegisterAccountService and redirects with notice' do
        service_instance = instance_double(Spl::RegisterAccountService)

        expect(Spl::RegisterAccountService).to receive(:new)
          .with(user, store, '123456')
          .and_return(service_instance)

        expect(service_instance).to receive(:call)

        expect(controller).to receive(:redirect_to).with(
          spree.edit_account_profile_path,
          hash_including(notice: Spree.t(:successfully_updated, resource: Spree.t(:account)))
        )

        controller.register_loyalty_account
      end
    end

    shared_examples 'register_loyalty_account error' do |error_class|
      xit "renders 422 and adds translated base error for #{error_class}" do
        payload = {
          'errorCode' => 'TEMPORARY_BLOCKED',
          'msg' => 'Temporarily blocked'
        }

        phone_obj = double('Phone', e164: '+48500600700')
        allow(user).to receive(:phone).and_return(phone_obj)

        service_instance = instance_double(Spl::RegisterAccountService)

        allow(Spl::RegisterAccountService).to receive(:new).and_return(service_instance)
        allow(service_instance).to receive(:call).and_raise(error_class.new(payload.inspect))

        expect(controller).to receive(:render).with(hash_including(status: :unprocessable_entity))

        controller.register_loyalty_account

        expect(user.errors.full_messages.join(' ')).to include(I18n.t('spl.errors.temporary_blocked'))
      end
    end

    context 'when RegisterAccountService raises error' do
      include_examples 'register_loyalty_account error', Spl::RegisterAccountService::SplRegisterAccountError
    end

    context 'when OauthTokenService raises error' do
      include_examples 'register_loyalty_account error', Spl::OauthTokenService::OauthTokenError
    end
  end
end
