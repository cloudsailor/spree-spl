# frozen_string_literal: true

module ProfileControllerHelper
  def render_login_code_error(user)
    render turbo_stream: turbo_stream.replace(
      'loyalty_connect_form',
      partial: 'spl/loyalty_connect_form',
      locals: { user: user }
    ),
           status: :unprocessable_content
  end

  def render_login_code_success(user, phone, partial)
    render turbo_stream: turbo_stream.replace(
      'loyalty_connect_form',
      partial: "spl/#{partial}",
      locals: {
        user: user,
        phone_e164: phone.respond_to?(:e164) ? phone.e164 : nil
      }
    ),
           status: :ok
  end

  def render_connect_loyalty_account_error(user, phone, partial)
    render turbo_stream: turbo_stream.replace(
      partial,
      partial: "spl/#{partial}",
      locals: {
        user: user,
        phone_e164: phone.respond_to?(:e164) ? phone.e164 : nil
      }
    ),
           status: :unprocessable_content
  end
end
