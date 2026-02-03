# frozen_string_literal: true

module Spl
  class ErrorTranslator
    I18N_BASE = 'spl.errors'

    def self.translate(payload, locale: I18n.locale)
      return translate_hash_payload(payload, locale) if payload.is_a?(Hash)

      translate_error_payload(payload)
    end

    def self.translate_hash_payload(payload, locale)
      code = payload['errorCode'].to_s.presence
      key  = "#{I18N_BASE}.#{code&.downcase}"
      if code && I18n.exists?(key, locale)
        I18n.t(key, locale:)
      else
        ::Spree::Spl.report_error(
          'Unknown Sparta error code',
          error_code: code,
          raw_msg: payload['msg'],
          payload: payload
        )

        I18n.t("#{I18N_BASE}.generic", locale:)
      end
    end

    def self.translate_error_payload(payload)
      payload.message if payload.respond_to?(:message)
    end

    private_class_method :translate_hash_payload, :translate_error_payload
  end
end
