# Spree SPL (SpartaLoyalty)

**Spree-spl** is a plugin that provides a promotion switcher for Spree, enabling enhanced loyalty program functionality.

## Installation

Add spree-spl to your Gemfile and run bundle install:

```sh
gem 'spree-spl'
```

_______
_______
_______

After installation, add the following line to `LineItemsControllerDecorator#create`:

```sh
add_spl_discount_params_to_order(spree_current_user, @order)
```

Add the following line to `Spree::Adjustable::AdjustmentsUpdaterDecorator#persist_totals`:

```sh
apply_spl_adjustments(attributes, totals)
```

Add the following lines to `Spree::OrderUpdaterDecorator#update_adjustment_total`:

```sh
skip_recalculation = check_spl_adjustments
return if skip_recalculation
```
_______

Additionally, Add the following lines to view spree/checkout/_line_item.html.erb

```sh
<% if spl_adjustment(line_item) %>
  <div class="flex justify-between">
  <span class="text-red-500">
    <%= spl_adjustment(line_item)&.label %>
  </span>
    <span class="text-red-500">
      <%= "#{spl_adjustment(line_item)&.amount} zł" %>
    </span>
  </div>
<% end %>
```



#### Add these methods to any other endpoints involved in processing an order in your repository.
