# frozen_string_literal: true

module Spree
  class Promotion
    module Rules
      module ItemTotalDecorator
        def eligible?(order, _options = {})
          return true if order.with_spl_adjustments?

          super
        end
      end
    end
  end
end
