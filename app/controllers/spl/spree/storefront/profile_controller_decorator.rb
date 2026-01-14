# frozen_string_literal: true

module Spl
  module Spree
    module Storefront
      module ProfileControllerDecorator
        include BooleanHelper

        def self.prepended(base)
          base.after_action :validate_spl_no_card, only: :update
        end

        private

        def user_params
          params.require(:user).permit(:first_name, :last_name, :phone, :email,
                                       public_metadata: %i[spl_card_active spl_no_card])
        end

        def validate_spl_no_card
          metadata = user_params[:public_metadata]
          return unless metadata&.[](:spl_no_card)

          update_order(metadata[:spl_no_card], metadata[:spl_card_active])
          validate_card(metadata)
        rescue ::Spl::ValidateCardService::SplCardValidationError => e
          handle_validation_error(e)
        end

        def validate_card(metadata)
          return unless disactivated_card?

          ::Spl::ValidateCardService.new(metadata[:spl_no_card], spree_current_user, current_store).call
        end

        def handle_validation_error(error)
          flash[:error] = error.message
          render :edit, status: :unprocessable_content
        end

        def update_order(spl_card, active)
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
          value = user_params.dig(:public_metadata, :spl_card_active)
          cast_boolean(value)
        end
      end
    end
  end
end
