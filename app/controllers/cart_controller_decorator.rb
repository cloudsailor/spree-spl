# frozen_string_literal: true

module CartControllerDecorator
  def create
    add_spl_discount_params_to_order(spree_current_user)

    super
  end

  def show
    promotion_switcher(spree_current_order, true)

    super
  end

  def update_spl_card_activate # rubocop:disable Metrics/AbcSize
    spree_authorize! :update, spree_current_order, order_token

    if params.dig('public_metadata', 'spl_card_active').nil?
      spree_current_order.errors.add(:base, I18n.t('order.loyalty_card_missing'))
      render_error_payload(spree_current_order.errors)
    else
      active_param = cast_boolean(params.dig('public_metadata', 'spl_card_active'))
      public_metadata = spree_current_order.public_metadata
      update_spl_card_active_param(spree_current_order, active_param, public_metadata)
      spree_current_order.reload
      promotion_switcher(spree_current_order, true)

      render_serialized_payload { serialized_current_order }
    end
  end

  private

  def promotion_switcher(order, check_only)
    PromotionSwitcherService.new(order, check_only).call
  end

  def update_spl_card_active_param(order, active_param, public_metadata)
    order.update(public_metadata: public_metadata.merge('spl_card_active' => active_param))
    order.promotions.destroy_all if order.promotions.any?
  end

  def add_spl_discount_params_to_order(user)
    return unless user.present?
    return unless user.public_metadata.key?(:spl_no_card) && user.public_metadata.key?(:spl_card_active)

    spl_card_active = cast_boolean(user.public_metadata['spl_card_active'])
    params[:public_metadata].merge!(spl_card_active: spl_card_active,
                                    spl_no_card: user.public_metadata['spl_no_card'])
  end

  def switch_spl_active_param(order, check_only)
    return unless order.public_metadata.key?(:spl_card_active)

    if order.public_metadata[:spl_card_active] == true
      order.update(public_metadata: order.public_metadata.merge(spl_card_active: false))
    else
      order.update(public_metadata: order.public_metadata.merge(spl_card_active: true))
    end

    promotion_switcher(order, check_only)
  end

  def assign_spl_active_param(order, user)
    return unless user.public_metadata.key?(:spl_card_active)

    active_param = cast_boolean(user.public_metadata[:spl_card_active])
    spl_card = user.public_metadata[:spl_no_card]
    order.update(public_metadata: order.public_metadata.merge(spl_card_active: active_param, spl_no_card: spl_card))
  end

  def maintain_spl_adjustments(order)
    return unless order.public_metadata.key?(:spl_card_active)

    order.update(public_metadata: order.public_metadata.merge(spl_card_active: true))
    promotion_switcher(order, true)
  end

  def cast_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
