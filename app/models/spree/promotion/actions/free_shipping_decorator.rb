# frozen_string_literal: true

module Spree
  class Promotion
    module Actions
      module FreeShippingDecorator
        def perform(payload = {})
          order = payload[:order]
          if ::Spl::ValidateCardService.new(order.user.public_metadata['spl_no_card'], order.user, order.store).call
            create_unique_adjustments(order, order.shipments)
          end
        end
      end
    end
  end
end
