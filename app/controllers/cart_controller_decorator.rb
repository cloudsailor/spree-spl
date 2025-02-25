# frozen_string_literal: true

module CartControllerDecorator
  def show
    apply_sparta_discount(spree_current_order, spree_current_user, check_only = true)

    super
  end

  def add_item
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
    apply_sparta_discount(spree_current_order, spree_current_user, check_only = true)
    spree_current_order.reload

    render_order(result)
  end

  def set_quantity
    return render_error_item_quantity unless params[:quantity].to_i > 0

    spree_authorize! :update, spree_current_order, order_token

    result = set_item_quantity_service.call(order: spree_current_order, line_item: line_item, quantity: params[:quantity])
    apply_sparta_discount(spree_current_order, spree_current_user, check_only = true)

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
      apply_sparta_discount(guest_order, spree_current_user, check_only = true)
      guest_order.reload
      render_serialized_payload { serialize_resource(guest_order) }
    else
      render_error_payload(result.error)
    end
  end

  def apply_coupon_code
    spree_authorize! :update, spree_current_order, order_token

    spree_current_order.coupon_code = params[:coupon_code]

    result = coupon_handler.new(spree_current_order).apply

    if result.error.blank?
      remove_sparta_discount(spree_current_order)
      render_serialized_payload { serialized_current_order }
    else
      render_error_payload(result.error)
    end
  end

  def remove_coupon_code
    spree_authorize! :update, spree_current_order, order_token

    coupon_codes = select_coupon_codes

    return render_error_payload(I18n.t('spree.api.v2.cart.no_coupon_code')) if coupon_codes.empty?

    result_errors = coupon_codes.count > 1 ? select_errors(coupon_codes) : select_error(coupon_codes)

    if result_errors.blank?
      apply_sparta_discount(spree_current_order, spree_current_user, check_only = true)
      render_serialized_payload { serialized_current_order }
    else
      render_error_payload(result_errors)
    end
  end

  private

  def apply_sparta_discount(order, user, check_only)
    return if spree_current_order.promotions.present?
    return unless order.line_items.any? && user.present?
    return unless user.public_metadata["spl_no_card"].present?

    spl_response = SpartaLoyaltyService.send_request(order.number,
                                                     user.public_metadata["spl_no_card"],
                                                     order.line_items,
                                                     DateTime.current,
                                                     order.products,
                                                     check_only)

    create_sparta_adjustments(spl_response, order) if spl_response.present?
  end

  def create_sparta_adjustments(spl_response, order)
    ApplySpartaDiscountService.new(spl_response, order).call
  end

  def remove_sparta_discount(order)
    RemoveSpartaDiscountService.new(order).call
  end
end
