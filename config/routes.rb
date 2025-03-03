# frozen_string_literal: true

Spree::Core::Engine.add_routes do
  namespace :api, defaults: { format: "json" } do
    namespace :v2 do
      namespace :storefront do
        resource :cart, controller: :cart, only: %i[show create destroy] do
          patch :update_spl_card_activate
        end
      end
    end
  end
end
