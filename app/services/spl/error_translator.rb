module Spl
  class ErrorTranslator
    I18N_BASE = "spl.errors".freeze

    def self.translate(payload, locale: I18n.locale)
      code = payload["errorCode"].to_s.presence
      # Example key: spl.errors.auth_temporary_blocked
      key  = "#{I18N_BASE}.#{code&.downcase}"

      if code && I18n.exists?(key, locale)
        I18n.t(key, locale:)
      else
        # report unknown code for later translations
        Spree::Spl.report_error(
          "Unknown Sparta error code",
          error_code: code,
          raw_msg: payload["msg"],
          payload: payload
        )

        I18n.t("#{I18N_BASE}.generic", locale:)
      end
    end
  end
end
