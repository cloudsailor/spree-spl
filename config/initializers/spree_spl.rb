# frozen_string_literal: true

Rails.application.config.to_prepare do
  ::Spree::Api::V2::Storefront::CartController.prepend(
    CartControllerDecorator
  )

  ::Spree::V2::Storefront::CartSerializer.prepend(
    CartSerializerDecorator
  )

  ::Spree::Api::V2::Storefront::CheckoutController.prepend(
    CheckoutControllerDecorator
  )

  ::Spree::Api::V2::Storefront::AccountController.prepend(
    AccountControllerDecorator
  )

  ::Spree::Adjustable::AdjustmentsUpdater.prepend(
    Spree::Adjustable::AdjustmentsUpdaterDecorator
  )

  ::Spree::OrderUpdater.prepend(
    OrderUpdaterDecorator
  )
end
