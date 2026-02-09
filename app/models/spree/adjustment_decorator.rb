# frozen_string_literal: true

module Spree
  module AdjustmentDecorator
    def self.prepended(base)
      base.include Spree::Preferences::Preferable

      base.preference :external_name, :string
      base.preference :trade_agreement_number, :string
      base.preference :external_source_type, :string
    end
  end
end
