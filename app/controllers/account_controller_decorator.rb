# frozen_string_literal: true

# Account decorator to validate spl card no
module AccountControllerDecorator
  def self.prepended(base)
    base.before_action :validate_spl_no_card, only: :update
  end

  private

  def validate_spl_no_card
    return unless user_update_params[:public_metadata][:spl_no_card].present?

    Spl::ValidateCardService.new(user_update_params[:public_metadata][:spl_no_card], spree_current_user).call
  rescue Spl::ValidateCardService::SplCardValidationError => e
    render json: { error: e.message }, status: :bad_request
  end
end
