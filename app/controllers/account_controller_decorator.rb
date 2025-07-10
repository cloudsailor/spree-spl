# frozen_string_literal: true

# Account decorator to validate spl card no
module AccountControllerDecorator
  def self.prepended(base)
    base.before_action :validate_spl_no_card, only: :update
  end

  def connect_loyalty_account
    spree_authorize! :update, spree_current_user
    Spl::LoginAccountService.new(DateTime.current, spree_current_user, params).call
    AssignSpartaCardNumberService.new(spree_current_user).call
    spree_current_user.reload
    render_serialized_payload { serialize_resource(spree_current_user) }
  rescue Spl::LoginAccountService::SplLoginAccountError, AssignSpartaCardNumberService::AssignSpartaCardNumberError,
         Spl::MeService::SplMeError => e
    render json: { error: e }, status: :bad_request
  end

  def register_loyalty_account
    spree_authorize! :update, spree_current_user
    Spl::RegisterAccountService.new(spree_current_user, params).call
    spree_current_user.reload
    render_serialized_payload { serialize_resource(spree_current_user) }
  rescue Spl::RegisterAccountService::SplRegisterAccountError, Spl::OauthTokenService::OauthTokenError => e
    render json: { error: e }, status: :bad_request
  end

  def registration_code
    Spl::RequestOtpService.new(DateTime.current, params).call
    head 204
  rescue Spl::RequestOtpService::SplRequestOtpError, Spl::OauthTokenService::OauthTokenError => e
    render json: { error: e }, status: :bad_request
  end

  def login_code
    spree_authorize! :update, spree_current_user
    Spl::SendOtpService.new(DateTime.current, params[:mobile_country], params[:phone_number]).call
    head 204
  rescue Spl::SendOtpService::SplSendOtpError => e
    render json: { error: e }, status: :bad_request
  end

  private

  def validate_spl_no_card # rubocop:disable Metrics/AbcSize
    return unless user_update_params[:public_metadata].present?
    return if disactivated_card
    return unless user_update_params[:public_metadata][:spl_no_card].present?

    Spl::ValidateCardService.new(user_update_params[:public_metadata][:spl_no_card], spree_current_user).call
  rescue Spl::ValidateCardService::SplCardValidationError => e
    update_order
    render json: { error: e.message }, status: :bad_request
  end

  def update_order(spl_card: nil, active: false)
    current_order = spree_current_user.orders.last
    return unless %w[cart address delivery payment].include?(current_order.state)

    current_order.update(
      public_metadata: current_order.public_metadata.merge(
        {
          'spl_no_card' => spl_card,
          'spl_card_active' => active
        }
      )
    )
  end

  def disactivated_card
    user_update_params[:public_metadata][:spl_card_active].present? &&
      !user_update_params[:public_metadata][:spl_card_active]
  end
end
