# frozen_string_literal: true

module ProfileControllerDecorator
  def self.prepended(base)
    base.before_action :validate_spl_no_card, only: :update
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone, :email,
                                 public_metadata: %i[spl_card_active spl_no_card])
  end

  def validate_spl_no_card
    return unless user_params[:public_metadata].present? && user_params[:public_metadata][:spl_no_card].present?
    return if disactivated_card?

    ::Spl::ValidateCardService.new(user_params[:public_metadata][:spl_no_card], spree_current_user, current_store).call
  rescue ::Spl::ValidateCardService::SplCardValidationError => e
    handle_validation_error(e)
  end

  def handle_validation_error(error)
    update_order
    flash[:error] = error.message
    render :edit, status: :unprocessable_entity
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

  def disactivated_card?
    user_params[:public_metadata][:spl_card_active].present? && !user_params[:public_metadata][:spl_card_active]
  end
end
