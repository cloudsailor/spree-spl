# Spree SPL (SpartaLoyalty)

**Spree-spl** is a plugin that provides a promotion switcher for Spree, enabling enhanced loyalty program functionality.

## Compatibility
### Versions <= 1.7.x
Are compatible with Spree ~> 4.x and Rails <= 7.2
### Versions > 1.7 (current master branch, check current state)
Is compatible with Spree ~> 5.2, and Rails >= 7.0, < 8.3
## Installation

Add spree-spl to your Gemfile and run bundle install:

```sh
gem 'spree-spl'
```

_______
_______
_______

To add JavaScript to your application, enter the following in the terminal:

```sh
bin/rails g spl:install
```


After installation, add the following line to `Spree::Adjustable::AdjustmentsUpdaterDecorator#persist_totals`:

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

## Testing
To run tests type in terminal:
```sh
bundle update
bundle exec rake test_app
bundle exec rspec
```

