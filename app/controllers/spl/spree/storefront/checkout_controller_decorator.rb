# frozen_string_literal: true

module Spl
  module Spree
    module Storefront
      module CheckoutControllerDecorator
        include BooleanHelper

        def self.prepended(base)
          base.before_action :promotion_switcher
        end

        private

        def promotion_switcher
          PromotionSwitcherService.new(@order, checkout_state_allowed?).call
          add_spl_discount_params_to_order(spree_current_user) if checkout_state_allowed?
        end

        def add_spl_discount_params_to_order(user)
          return if user.blank?
          return unless user.public_metadata.key?('spl_no_card') && user.public_metadata.key?('spl_card_active')

          current_order.update(public_metadata: current_order.public_metadata.merge(
            {
              'spl_no_card' => user.public_metadata['spl_no_card'],
              'spl_card_active' => cast_boolean(user.public_metadata['spl_card_active'])
            }
          ))
        end

        def checkout_state_allowed?
          %w[cart address delivery payment].include?(request.path.split('/').last)
        end
      end
    end
  end
end
