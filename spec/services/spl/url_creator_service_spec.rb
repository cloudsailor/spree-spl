# spec/services/spl/url_creator_service_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spl::UrlCreatorService, type: :service do
  subject(:service) { described_class.new(base_url) }
  let(:base_url) { 'https://example.test' }

  describe '#check_card' do
    it 'builds the checkCard URL' do
      expect(service.check_card).to eq('https://example.test/api/tx/checkCard')
    end
  end

  describe '#find' do
    it 'builds the find URL' do
      expect(service.find).to eq('https://example.test/api/tx/find')
    end
  end

  describe '#sale' do
    it 'builds the sale URL' do
      expect(service.sale).to eq('https://example.test/api/tx/sale')
    end
  end

  describe '#sale_refund' do
    it 'builds the saleRefund URL' do
      expect(service.sale_refund).to eq('https://example.test/api/tx/saleRefund')
    end
  end

  describe '#me' do
    it 'builds the me URL' do
      expect(service.me).to eq('https://example.test/api/cwp/customer/me')
    end
  end

  describe '#register' do
    it 'builds the register URL' do
      expect(service.register).to eq('https://example.test/api/cwp/customer/register')
    end
  end

  describe '#request_otp' do
    it 'builds the requestOTP URL' do
      expect(service.request_otp).to eq('https://example.test/api/cwp/customer/requestOTP')
    end
  end

  describe '#login' do
    it 'builds the login URL' do
      expect(service.login).to eq('https://example.test/api/oauth/login')
    end
  end

  describe '#send_otp' do
    it 'builds the sendOTP URL' do
      expect(service.send_otp).to eq('https://example.test/api/oauth/sendOTP')
    end
  end

  describe '#oauth_token' do
    it 'builds the token URL' do
      expect(service.oauth_token).to eq('https://example.test/api/oauth/token')
    end
  end

  context 'when base url has a trailing slash' do
    let(:base_url) { 'https://example.test/' }

    it 'keeps the double slash behavior (document current behavior)' do
      expect(service.me).to eq('https://example.test//api/cwp/customer/me')
    end
  end
end
