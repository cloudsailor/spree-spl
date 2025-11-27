# frozen_string_literal: true

module Spree
  class Promotion
    module Rules
      module ItemTotalDecorator
        def eligible?(order, _options = {})
          return true if ::Spl::ValidateCardService.new(order.user.public_metadata['spl_no_card'],
                                                        order.user, order.store).call

          super
        end
      end
    end
  end
end
