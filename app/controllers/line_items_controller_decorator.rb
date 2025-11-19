# frozen_string_literal: true

module LineItemsControllerDecorator
  private

  def add_spl_discount_params_to_order(user, order)
    return if user.blank?
    return unless user.public_metadata.key?('spl_no_card') && user.public_metadata.key?('spl_card_active')

    spl_card_active = cast_boolean(user.public_metadata['spl_card_active'])
    order.public_metadata.merge!(spl_card_active: spl_card_active, spl_no_card: user.public_metadata['spl_no_card'])
    order.save
  end

  def cast_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
