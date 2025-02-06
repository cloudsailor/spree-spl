# frozen_string_literal: true

module Spree
  module V2
    module Storefront
      class AdjustmentSerializer < ::Spree::V2::Storefront::BaseSerializer
        set_type :adjustment

        attributes :label, :amount, :display_amount, :eligible, :created_at, :updated_at
      end
    end
  end
end
