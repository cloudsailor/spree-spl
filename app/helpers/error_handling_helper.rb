# frozen_string_literal: true

module ErrorHandlingHelper
  # Parses and translate occurred error, then adds it to user errors.
  # Dedicated for storefront controllers.
  # @param [StandardError]
  def handle_spl_error(error)
    payload = Spl::ErrorPayloadParser.parse(error.message) || error
    msg = Spl::ErrorTranslator.translate(payload)

    clear_errors
    try_spree_current_user.errors.add(:base, msg)
  end

  def clear_errors
    try_spree_current_user.errors.clear
  end

  def token_expired?(err_msg)
    err_msg == 'TOKEN_EXPIRED'
  end
end
