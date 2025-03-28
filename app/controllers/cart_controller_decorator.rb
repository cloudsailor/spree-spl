# frozen_string_literal: true

module CartControllerDecorator
  def create
    add_spl_discount_params_to_order(spree_current_user)

    super
  end

  def show
    Rails.logger.debug spree_current_user.email if spree_current_user.present?
    promotion_switcher(spree_current_order, spree_current_user, true)

    super
  end

  def update_spl_card_activate # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    if params.dig('public_metadata', 'spl_card_active').nil?
      spree_current_order.errors.add(:base, I18n.t('order.loyalty_card_missing'))
      render_error_payload(spree_current_order.errors)
    else
      active_param = cast_boolean(params.dig('public_metadata', 'spl_card_active'))
      public_metadata = spree_current_order.public_metadata
      spree_current_order.update(public_metadata: public_metadata.merge('spl_card_active' => active_param))
      spree_current_order.reload
      promotion_switcher(spree_current_order, spree_current_user, true)

      render_serialized_payload { serialized_current_order }
    end
  end

  private

  def promotion_switcher(order, user, check_only)
    Rails.logger.debug order.public_metadata[:spl_no_card] if order.public_metadata.key?(:spl_no_card)
    PromotionSwitcherService.new(order, user, check_only).call
  end

  def add_spl_discount_params_to_order(user)
    return unless user.present?
    return unless user.public_metadata.key?(:spl_no_card) && user.public_metadata.key?(:spl_card_active)

    spl_card_active = cast_boolean(user.public_metadata['spl_card_active'])
    params[:public_metadata].merge!("spl_card_active": spl_card_active,
                                    "spl_no_card": user.public_metadata['spl_no_card'])
  end

  def switch_spl_active_param(order, user, check_only)
    return unless order.public_metadata.key?(:spl_card_active)

    if order.public_metadata[:spl_card_active] == true
      order.update(public_metadata: order.public_metadata.merge("spl_card_active": false))
    else
      order.update(public_metadata: order.public_metadata.merge("spl_card_active": true))
    end

    promotion_switcher(order, user, check_only)
  end

  def assign_spl_active_param(order, user)
    return unless user.public_metadata.key?(:spl_card_active)

    active_param = cast_boolean(user.public_metadata[:spl_card_active])
    spl_card = user.public_metadata[:spl_no_card]
    order.update(public_metadata: order.public_metadata.merge("spl_card_active": active_param, "spl_no_card": spl_card))
  end

  def maintain_spl_adjustments(order, user)
    return unless order.public_metadata.key?(:spl_card_active)

    order.update(public_metadata: order.public_metadata.merge("spl_card_active": true))
    promotion_switcher(order, user, true)
  end

  def cast_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
