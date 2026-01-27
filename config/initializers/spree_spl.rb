# frozen_string_literal: true

Rails.application.config.to_prepare do # rubocop:disable Metrics/BlockLength
  ::Spree::Api::V2::Storefront::CartController.prepend(
    Spl::Spree::Api::CartControllerDecorator
  )

  ::Spree::V2::Storefront::CartSerializer.prepend(
    CartSerializerDecorator
  )

  ::Spree::Api::V2::Storefront::CheckoutController.prepend(
    Spl::Spree::Api::CheckoutControllerDecorator
  )

  ::Spree::Api::V2::Storefront::AccountController.prepend(
    Spl::Spree::Api::AccountControllerDecorator
  )

  ::Spree::Adjustable::AdjustmentsUpdater.prepend(
    Spree::Adjustable::AdjustmentsUpdaterDecorator
  )

  ::Spree::PromotionHandler::Cart.prepend(
    CartDecorator
  )

  ::Spree::OrderUpdater.prepend(
    OrderUpdaterDecorator
  )

  ::Spree::CheckoutController.prepend(
    Spl::Spree::Storefront::CheckoutControllerDecorator
  )

  ::Spree::LineItemsController.prepend(
    Spl::Spree::Storefront::LineItemsControllerDecorator
  )

  ::Spree::Account::ProfileController.prepend(
    Spl::Spree::Storefront::ProfileControllerDecorator
  )

  ::Spree::Admin::PaymentsController.prepend(
    Spl::Spree::Admin::PaymentsControllerDecorator
  )

  ::Spree::CheckoutHelper.prepend(
    CheckoutHelperDecorator
  )

  ::Spree::Promotion::Rules::UserFromClub
  Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::UserFromClub
end
