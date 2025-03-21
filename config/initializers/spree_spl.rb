# frozen_string_literal: true

Rails.application.config.after_initialize do
  ::Spree::V2::Storefront::CartSerializer.prepend CartSerializerDecorator
  ::Spree::Api::V2::Storefront::CartController.prepend CartControllerDecorator
  ::Spree::Api::V2::Storefront::CheckoutController.prepend CheckoutControllerDecorator
  ::Spree::Api::V2::Storefront::AccountController.prepend AccountControllerDecorator
  ::Spree::Adjustable::AdjustmentsUpdater.prepend Spree::Adjustable::AdjustmentsUpdaterDecorator
  ::Spree::OrderUpdater.prepend OrderUpdaterDecorator
end
