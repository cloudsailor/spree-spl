# Spree SPL (SpartaLoyalty)

**Spree-spl** is a plugin that provides a promotion switcher for Spree, enabling enhanced loyalty program functionality.

## Installation

Add spree-spl to your Gemfile and run bundle install:

```sh
gem 'spree-seo'
```

_______
_______
_______

After installation, add the following methods to `CartControllerDecorator`:

```sh
promotion_switcher(spree_current_order, spree_current_user, check_only)
spree_current_order.reload
```

These methods must be manually added to your repository in the Storefront endpoints:

* `add_item`
* `set_quantity`

_______

Add the following method to `AccountControllerDecorator`:
```sh
module AccountControllerDecorator
  def user_update_params
    public_metadata = super['public_metadata']

    params = super
    if public_metadata['spl_no_card'].present? && public_metadata['spl_card_active'].nil?
      update_order(spl_card: public_metadata['spl_no_card'], active: true)
      params[:public_metadata] = params[:public_metadata].merge({ 'spl_card_active' => true })
    elsif public_metadata['spl_no_card'].present?
      update_order(spl_card: public_metadata['spl_no_card'], active: public_metadata['spl_card_active'])
    else
      update_order(spl_card: public_metadata['spl_no_card'])
    end

    public_metadata['spl_no_card'].present? ? params : super
  end
end
```
_______

Additionally, the following methods must be manually added to your repository in the Storefront endpoint `associate`:

```sh
promotion_switcher(spree_current_order, spree_current_user, check_only)
spree_current_order.reload
```

_______

For the Storefront endpoint `apply_coupon_code`, add the following method before the `coupon_handler` method: 

```sh
switch_spl_active_param(spree_current_order, spree_current_user, check_only)
```

Then, before `render_error_payload`, include:

```sh
unless [:coupon_code_already_applied].include?(result.status_code)
    maintain_spl_adjustments(spree_current_order, spree_current_user)
end
```

_______

Finally, for the Storefront endpoint `remove_coupon_code`, manually add the following methods to your repository:

```sh
switch_spl_active_param(spree_current_order, spree_current_user, check_only)
spree_current_order.reload
```

_______
_______
_______

Next, add the following methods to `CheckoutControllerDecorator`:

```sh
promotion_switcher(result.value, spree_current_user, check_only)
```

These methods must be manually added to your repository in the Storefront endpoints before `render_order`:

* `update`
* `complete`

_______
_______
_______

Also, add the following methods manually to `AdjustmentUpdaterDecorator` to method `persist_totals`:

```sh
set_spree_adjustments if shipment_with_adjustments? || order_with_adjustments?
recalculate_spl_adjustments(attributes, totals) if line_item_with_spl_adjustments?
```

_______

#### Add these methods to any other endpoints involved in processing an order in your repository.

## Testing
To run tests type in terminal:
```sh
bundle update
bundle exec rake test_app
bundle exec rspec
```

