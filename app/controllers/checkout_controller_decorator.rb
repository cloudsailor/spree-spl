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

    apply_sparta_discount(result.value, spree_current_user, check_only = true)

    render_order(result)
  end

  def complete
    spree_authorize! :update, spree_current_order, order_token

    result = complete_service.call(order: spree_current_order)

    apply_sparta_discount(result.value, spree_current_user, check_only = false)

    render_order(result)
  end

  private

  def apply_sparta_discount(order, user, check_only)
    return unless order.line_items.any? && user.present?
    return unless user.public_metadata["spl_no_card"].present?

    spl_response = SpartaLoyaltyService.send_request(order.number,
                                                     user.public_metadata["spl_no_card"],
                                                     order.line_items,
                                                     DateTime.current,
                                                     order.products,
                                                     check_only)

    if spl_response.present?
      spree_current_order.promotions.delete_all if spree_current_order.promotions.any?
      create_sparta_adjustments(spl_response, order)
    end
  end

  def create_sparta_adjustments(spl_response, order)
    ApplySpartaDiscountService.new(spl_response, order).call
  end

  def remove_sparta_discount(order)
    RemoveSpartaDiscountService.new(order).call
  end
end
