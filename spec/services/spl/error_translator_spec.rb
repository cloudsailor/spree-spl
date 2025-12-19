# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spl::ErrorTranslator do
  describe '.translate' do
    let(:locale) { :en }

    before do
      stub_const('Spree::Spl', Module.new) unless defined?(Spree::Spl)
      allow(Spree::Spl).to receive(:report_error).and_return(nil)
    end

    around do |example|
      I18n.with_locale(locale) do
        example.run
      end
    end

    context 'when errorCode is present and translation key exists' do
      let(:temporary_blocked_payload) do
        { 'errorCode' => 'TEMPORARY_BLOCKED', 'msg' => 'Temporarily blocked' }
      end

      it 'returns the translated message and does not report error' do
        expect(Spree::Spl).not_to receive(:report_error)

        expected = I18n.t('spl.errors.temporary_blocked', locale: locale)
        expect(described_class.translate(temporary_blocked_payload, locale: locale)).to eq(expected)
      end
    end

    context 'when translation key does not exist' do
      let(:unknown_code_payload) do
        { 'errorCode' => 'SOME_NEW_CODE', 'msg' => 'Raw message' }
      end

      it 'reports error and returns generic translation' do
        expect(Spree::Spl).to receive(:report_error).with(
          'Unknown Sparta error code',
          hash_including(
            error_code: 'SOME_NEW_CODE',
            raw_msg: 'Raw message',
            payload: unknown_code_payload
          )
        )

        expected = I18n.t('spl.errors.generic', locale: locale)
        expect(described_class.translate(unknown_code_payload, locale: locale)).to eq(expected)
      end
    end

    context 'when errorCode is nil/blank' do
      let(:nil_code_payload) do
        { 'errorCode' => nil, 'msg' => 'Raw message' }
      end

      it 'reports error and returns generic translation' do
        expect(Spree::Spl).to receive(:report_error).with(
          'Unknown Sparta error code',
          hash_including(
            error_code: nil,
            raw_msg: 'Raw message',
            payload: nil_code_payload
          )
        )

        expected = I18n.t('spl.errors.generic', locale: locale)
        expect(described_class.translate(nil_code_payload, locale: locale)).to eq(expected)
      end
    end

    context 'when locale is passed explicitly' do
      it 'uses the provided locale for lookup and translation' do
        payload = { 'errorCode' => 'TEMPORARY_BLOCKED' }
        pl = :pl

        # jeśli masz pl.yml w appce, to wystarczy:
        # expected = I18n.t('spl.errors.temporary_blocked', locale: pl)

        # jeśli NIE masz pl.yml, ale chcesz przetestować ścieżkę "locale param działa":
        I18n.backend.store_translations(pl, spl: { errors: { temporary_blocked: 'PL message' } })
        expected = I18n.t('spl.errors.temporary_blocked', locale: pl)

        expect(described_class.translate(payload, locale: pl)).to eq(expected)
      end
    end
  end
end
