# frozen_string_literal: true

module CheckoutControllerDecorator
  def update
    spree_authorize! :update, spree_current_order, order_token

    result = update_service.call(
      order: spree_current_order,
      params: params,
      permitted_attributes: permitted_checkout_attributes,
      request_env: request.headers.env
    )
    # LOYALTY PROGRAM START - Do not remove or modify
    promotion_switcher(result.value, spree_current_user, true)
    # LOYALTY PROGRAM END
    render_order(result)
  end

  def complete
    spree_authorize! :update, spree_current_order, order_token

    result = complete_service.call(order: spree_current_order)
    # LOYALTY PROGRAM START - Do not remove or modify
    promotion_switcher(result.value, spree_current_user, false)
    # LOYALTY PROGRAM END
    render_order(result)
  end

  private

  def promotion_switcher(order, user, check_only)
    PromotionSwitcher.new(order, user, check_only).call
  end
end
