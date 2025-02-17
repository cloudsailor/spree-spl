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

    apply_sparta_discount(result.value, spree_current_user)

    render_order(result)
  end

  private

  def apply_sparta_discount(order, user)
    return unless order.line_items.any? && user.present?
    return unless user.public_metadata["spl_no_card"].present?

    check_only = true
    spl_response = SpartaLoyaltyService.send_request(order.number,
                                                     user.public_metadata["spl_no_card"],
                                                     order.line_items,
                                                     DateTime.current,
                                                     order.products,
                                                     check_only)
    spree_current_order.promotions.delete_all if spree_current_order.promotions.any?
    create_sparta_adjustments(spl_response, order)
  end

  def create_sparta_adjustments(spl_response, order)
    ApplySpartaDiscountService.new(spl_response, order).call
  end

  def remove_sparta_discount(order)
    RemoveSpartaDiscountService.new(order).call
  end
end
