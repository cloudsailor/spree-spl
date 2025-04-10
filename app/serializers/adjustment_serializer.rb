# frozen_string_literal: true

class AdjustmentSerializer < ::Spree::V2::Storefront::BaseSerializer
  set_type :adjustment

  attributes :label, :amount, :display_amount, :eligible, :created_at, :updated_at
end
