# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spl::ErrorTranslator do
  describe '.translate' do
    let(:locale) { :en }

    before do
      stub_const('Spree::Spl', Module.new) unless defined?(Spree::Spl)
      allow(Spree::Spl).to receive(:report_error).and_return(nil)
    end

    context 'when errorCode is present and translation key exists' do
      let(:temporary_blocked_payload) do
        { 'errorCode' => 'TEMPORARY_BLOCKED', 'msg' => 'Temporarily blocked' }
      end
      let(:temporary_blocked_key) { 'spl.errors.temporary_blocked' }

      it 'returns the translated message and does not report error' do
        expect(I18n).to receive(:exists?).with(temporary_blocked_key, locale).and_return(true)
        expect(I18n).to receive(:t).with(temporary_blocked_key, locale: locale).and_return('Translated message')
        expect(Spree::Spl).not_to receive(:report_error)
        expect(described_class.translate(temporary_blocked_payload, locale: locale)).to eq('Translated message')
      end
    end

    context 'when translation key does not exist' do
      let(:unknown_code_payload) do
        { 'errorCode' => 'SOME_NEW_CODE', 'msg' => 'Raw message' }
      end
      let(:some_new_code_key) { 'spl.errors.some_new_code' }
      it 'reports error and returns generic translation' do
        expect(I18n).to receive(:exists?).with(some_new_code_key, locale).and_return(false)
        expect(Spree::Spl).to receive(:report_error).with(
          'Unknown Sparta error code',
          hash_including(
            error_code: 'SOME_NEW_CODE',
            raw_msg: 'Raw message',
            payload: unknown_code_payload
          )
        )
        expect(I18n).to receive(:t).with('spl.errors.generic', locale: locale).and_return('Generic message')
        expect(described_class.translate(unknown_code_payload, locale: locale)).to eq('Generic message')
      end
    end

    context 'when errorCode is nil/blank' do
      let(:nil_code_payload) do
        { 'errorCode' => nil, 'msg' => 'Raw message' }
      end
      it 'reports error and returns generic translation' do
        expect(I18n).not_to receive(:exists?)
        expect(Spree::Spl).to receive(:report_error).with(
          'Unknown Sparta error code',
          hash_including(
            error_code: nil,
            raw_msg: 'Raw message',
            payload: nil_code_payload
          )
        )
        expect(I18n).to receive(:t).with('spl.errors.generic', locale: locale).and_return('Generic message')

        expect(described_class.translate(nil_code_payload, locale: locale)).to eq('Generic message')
      end
    end

    context 'when locale is passed explicitly' do
      it 'uses the provided locale for lookup and translation' do
        payload = { 'errorCode' => 'TEMPORARY_BLOCKED' }
        pl = :pl
        key = 'spl.errors.temporary_blocked'

        expect(I18n).to receive(:exists?).with(key, pl).and_return(true)
        expect(I18n).to receive(:t).with(key, locale: pl).and_return('PL message')

        expect(described_class.translate(payload, locale: pl)).to eq('PL message')
      end
    end
  end
end
