Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Devise authentication routes
  devise_options = {controllers: {}}
  devise_options[:controllers][:omniauth_callbacks] = "users/omniauth_callbacks" if OIDC_ENABLED
  devise_options[:controllers][:sessions] = "sessions" if OIDC_ENABLED
  devise_options[:controllers][:registrations] = "users/registrations" if REGISTRATION_ENABLED
  devise_for :users, **devise_options

  root "teams#show"

  # Teams routes
  resources :teams, only: [:index, :show] do
    resources :technologies, only: [:show], controller: "team_technologies"
  end

  # Unit routes
  resources :units, only: [:index, :show]

  # User routes
  resources :users, only: [:show] do
    resource :skill_ratings, only: [:show, :edit, :update] do
      post :submit
      post :approve_all
    end
    resources :skill_ratings, only: [] do
      member do
        post :approve
        post :reject
      end
    end
  end

  # Locale switching
  post "locale/:locale", to: "locales#switch", as: :switch_locale

  # Theme switching
  post "theme/:theme", to: "themes#switch", as: :switch_theme

  get "coverage_index_history", to: "coverage_index_history#index"
  get "maturity_index_history", to: "maturity_index_history#index"

  # Admin namespace
  namespace :admin do
    root to: "dashboard#index"
    resources :technologies do
      collection do
        get :reorder
        patch :reorder
      end
    end
    resources :units
    resources :teams do
      resources :team_technologies, only: [:new, :create, :edit, :update, :destroy] do
        member do
          patch :restore
        end
      end
    end
    resources :users, only: [:index, :show, :new, :create, :edit, :update]
    resources :quarters do
      member do
        post :activate
        post :close
        post :archive
      end
    end
  end
end
