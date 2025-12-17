# frozen_string_literal: true

module LineItemsControllerDecorator
  include BooleanHelper

  def self.prepended(base)
    base.before_action :add_spl_discount_params_to_order, only: :create
  end

  private

  def add_spl_discount_params_to_order
    user = spree_current_user
    return if user.blank?
    return unless user.public_metadata.key?('spl_no_card') && user.public_metadata.key?('spl_card_active')

    spl_card_active = cast_boolean(user.public_metadata['spl_card_active'])
    order = current_order(create_order_if_necessary: true)
    order.public_metadata.merge!(spl_card_active: spl_card_active, spl_no_card: user.public_metadata['spl_no_card'])
    order.save
  end
end
