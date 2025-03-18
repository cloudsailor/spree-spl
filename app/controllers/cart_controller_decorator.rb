# frozen_string_literal: true

module CartControllerDecorator # rubocop:disable Metrics/ModuleLength
  def create
    add_spl_discount_params_to_order(spree_current_user)

    super
  end

  def show
    promotion_switcher(spree_current_order, spree_current_user, true)

    super
  end

  def add_item # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    spree_authorize! :update, spree_current_order, order_token
    spree_authorize! :show, @variant

    result = add_item_service.call(
      order: spree_current_order,
      variant: @variant,
      quantity: add_item_params[:quantity],
      public_metadata: add_item_params[:public_metadata],
      private_metadata: add_item_params[:private_metadata],
      options: add_item_params[:options]
    )

    promotion_switcher(spree_current_order, spree_current_user, true)
    spree_current_order.reload

    render_order(result)
  end

  def set_quantity # rubocop:disable Metrics/AbcSize
    return render_error_item_quantity unless params[:quantity].to_i > 0 # rubocop:disable Style/NumericPredicate

    spree_authorize! :update, spree_current_order, order_token

    result = set_item_quantity_service.call(order: spree_current_order,
                                            line_item: line_item,
                                            quantity: params[:quantity])
    promotion_switcher(spree_current_order, spree_current_user, true)
    spree_current_order.reload

    render_order(result)
  end

  def associate # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    guest_order_token = params[:guest_order_token]
    guest_order = ::Spree::Api::Dependencies.storefront_current_order_finder.constantize.new.execute(
      store: current_store,
      user: nil,
      token: guest_order_token,
      currency: current_currency
    )

    spree_authorize! :update, guest_order, guest_order_token

    result = associate_service.call(guest_order: guest_order, user: spree_current_user)

    if result.success?
      assign_spl_active_param(guest_order, spree_current_user)
      promotion_switcher(guest_order, spree_current_user, true)
      guest_order.reload
      render_serialized_payload { serialize_resource(guest_order) }
    else
      render_error_payload(result.error)
    end
  end

  def apply_coupon_code # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    spree_authorize! :update, spree_current_order, order_token

    spree_current_order.coupon_code = params[:coupon_code]
    switch_spl_active_param(spree_current_order, spree_current_user, true)
    result = coupon_handler.new(spree_current_order).apply

    if result.error.blank?
      render_serialized_payload { serialized_current_order }
    else
      unless [:coupon_code_already_applied].include?(result.status_code)
        maintain_spl_adjustments(spree_current_order, spree_current_user)
      end
      render_error_payload(result.error)
    end
  end

  def remove_coupon_code # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    spree_authorize! :update, spree_current_order, order_token

    coupon_codes = select_coupon_codes

    return render_error_payload(I18n.t("spree.api.v2.cart.no_coupon_code")) if coupon_codes.empty?

    result_errors = coupon_codes.count > 1 ? select_errors(coupon_codes) : select_error(coupon_codes)

    if result_errors.blank?
      switch_spl_active_param(spree_current_order, spree_current_user, true)
      spree_current_order.reload
      render_serialized_payload { serialized_current_order }
    else
      render_error_payload(result_errors)
    end
  end

  def update_spl_card_activate
    active_param = ActiveModel::Type::Boolean.new.cast(params.dig("public_metadata", "spl_card_active"))
    spree_current_order.update(public_metadata: spree_current_order.public_metadata.merge("spl_card_active" => active_param)) # rubocop:disable Layout/LineLength
    spree_current_order.reload
    promotion_switcher(spree_current_order, spree_current_user, true)

    render_serialized_payload { serialized_current_order }
  end

  private

  def promotion_switcher(order, user, check_only)
    PromotionSwitcher.new(order, user, check_only).call
  end

  def add_spl_discount_params_to_order(user)
    return unless user.present?

    return unless user.public_metadata.key?(:spl_no_card) && user.public_metadata.key?(:spl_card_active)

    spl_card_active = ActiveModel::Type::Boolean.new.cast(user.public_metadata["spl_card_active"])
    params[:public_metadata].merge!("spl_card_active": spl_card_active,
                                    "spl_no_card": user.public_metadata["spl_no_card"])
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

    active_param = ActiveModel::Type::Boolean.new.cast(user.public_metadata[:spl_card_active])
    spl_card = user.public_metadata[:spl_no_card]
    order.update(public_metadata: order.public_metadata.merge("spl_card_active": active_param, "spl_no_card": spl_card))
  end

  def maintain_spl_adjustments(order, user)
    return unless order.public_metadata.key?(:spl_card_active)

    order.update(public_metadata: order.public_metadata.merge("spl_card_active": true))
    promotion_switcher(order, user, true)
  end
end
