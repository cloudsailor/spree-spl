# frozen_string_literal: true

Spree::Core::Engine.add_routes do
  namespace :api, defaults: { format: 'json' } do
    namespace :v2 do
      namespace :storefront do
        resource :cart, controller: :cart, only: %i[show create destroy] do
          patch :update_spl_card_activate, to: 'cart#update_spl_card_activate'
        end
        resource :account, controller: :account, only: %i[show create update] do
          patch :login_code, to: 'account#login_code'
          patch :registration_code, to: 'account#registration_code'
          post :connect_loyalty_account, to: 'account#connect_loyalty_account'
          post :register_loyalty_account, to: 'account#register_loyalty_account'
        end
      end
    end
  end
  namespace :account do
    resource :profile, controller: :profile, only: [:edit, :update] do
      patch :registration_code
      post :register_loyalty_account
      patch :login_code
      post :connect_loyalty_account
    end
  end
end
