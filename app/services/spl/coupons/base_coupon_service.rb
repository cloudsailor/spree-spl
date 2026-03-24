# frozen_string_literal: true

require 'json'

module Spl
  module Coupons
    class BaseCouponService
      class BaseCouponServiceError < StandardError; end
      include SplServiceHelper
      include ErrorHandlingHelper
      include LoginCheckHelper

      def satisfied_preconditions?(private_metadata)
        user_has_private_metadata?(private_metadata) &&
          logged_user?(@user)
      end

      def user_has_private_metadata?(private_metadata)
        private_metadata.present?
      end
    end
  end
end
