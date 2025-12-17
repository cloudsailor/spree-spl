class AddCouponsInCheckout
  Deface::Override.new(
    virtual_path: 'spree/checkout/_sidebar',
    name: 'add_coupons_in_checkout',
    insert_before: '.summary-content',
    text: <<-ERB
     <%= render partial: 'spree/checkout/spl_coupons' %>
    ERB
  )
end