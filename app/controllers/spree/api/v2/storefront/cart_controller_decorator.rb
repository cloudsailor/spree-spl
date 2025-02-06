# frozen_string_literal: true

module Spree
  module V2
    module Storefront
      module CartControllerDecorator
        def show
          debugger
          apply_sparta_discount(spree_current_order, spree_current_user)

          super
        end

        def associate # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          guest_order_token = params[:guest_order_token]
          guest_order = ::Spree::Api::Dependencies.storefront_current_order_finder.constantize.new.execute(
            store: current_store,
            user: nil,
            token: guest_order_token,
            currency: current_currency
          )

          spree_authorize! :update, guest_order, guest_order_token

          result = associate_service.call(guest_order: guest_order, user: spree_current_user)

          if result.success?
            apply_sparta_discount(guest_order, spree_current_user)
            guest_order.reload
            render_serialized_payload { serialize_resource(guest_order) }
          else
            render_error_payload(result.error)
          end
        end

        def apply_coupon_code
          remove_sparta_discount(spree_current_order)

          super
        end

        def remove_coupon_code
          apply_sparta_discount(spree_current_order, spree_current_user)

          super
        end

        private

        def apply_sparta_discount(order, user)
          return unless order.line_items.any? && user.present?
          return unless user.public_metadata["spl_no_card"].present?

          check_only = true
          spl_response = SpartaLoyaltyService.send_request(order.number,
                                                           user.public_metadata["spl_no_card"],
                                                           order.line_items,
                                                           DateTime.current,
                                                           order.products,
                                                           check_only)
          create_sparta_adjustments(spl_response, order)
        end

        def create_sparta_adjustments(spl_response, order)
          ApplySpartaDiscountService.new(spl_response, order).call
        end

        def remove_sparta_discount(order)
          RemoveSpartaDiscountService.new(order).call
        end
      end
    end
  end
end

if ::Spree::Api::V2::Storefront::CartController
   .included_modules.exclude?(Spree::V2::Storefront::CartControllerDecorator)
  ::Spree::Api::V2::Storefront::CartController.prepend Spree::V2::Storefront::CartControllerDecorator
end
