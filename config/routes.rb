Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Devise authentication routes
  devise_for :users

  root "teams#show"

  # Teams routes
  resources :teams, only: [:index, :show]

  # Unit routes
  resources :units, only: [:index, :show]

  # User routes
  resources :users, only: [:show] do
    resource :skill_ratings, only: [:show, :edit, :update]
  end

  # Locale switching
  post "locale/:locale", to: "locales#switch", as: :switch_locale

  # Theme switching
  post "theme/:theme", to: "themes#switch", as: :switch_theme

  # Admin namespace
  namespace :admin do
    root to: "dashboard#index"
    resources :technologies do
      collection do
        get :reorder
        patch :reorder
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
