# frozen_string_literal: true

module ProfileControllerDecorator
  def self.prepended(base)
    base.before_action :validate_login_code_request, only: :login_code
  end

  def login_code
    phone = phone_parser
    Spl::SendOtpService.new(DateTime.current, phone.country_code, phone.national_number, current_store).call
    try_spree_current_user.update!(public_metadata: (try_spree_current_user.public_metadata || {}).merge('accept_yc_terms' => true))
  rescue Spl::SendOtpService::SplSendOtpError => e
    clear_login_code_errors
    try_spree_current_user.errors.add(:base, e.message.presence || I18n.t('spl.user.errors.otp_send_failed'))

    render_login_code_error
  end

  private

  def validate_login_code_request
    clear_login_code_errors
    validate_yc_terms
    validate_phone

    render_login_code_error if try_spree_current_user.errors.any?
  end

  def validate_yc_terms
    return if yc_terms_accepted?

    try_spree_current_user.errors.add(:base, I18n.t('spl.user.errors.must_accept_yc_terms'))
  end

  def validate_phone
    return if phone_parser.valid?

    try_spree_current_user.errors.add(:phone, I18n.t('spl.user.errors.invalid_phone'))
  end

  def yc_terms_accepted?
    ActiveModel::Type::Boolean.new.cast(login_code_params[:accept_yc_terms])
  end

  def phone_parser
    PhoneParserService.new(login_code_params[:phone])
  end

  def clear_login_code_errors
    try_spree_current_user.errors.clear
  end

  def render_login_code_error
    render turbo_stream: turbo_stream.replace(
      'loyalty_connect_form',
      partial: 'spl/loyalty_connect_form',
      locals: { user: try_spree_current_user }
    ),
           status: :unprocessable_entity
  end

  def login_code_params
    params.require(:user).permit(:phone, :accept_yc_terms)
  end
end
