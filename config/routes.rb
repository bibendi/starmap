Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Devise authentication routes
  devise_for :users

  root "teams#show"

  # Teams routes
  get "/teams", to: "teams#index", as: :teams
  get "/team", to: "teams#show", as: :team

  # Unit routes
  get "/units", to: "units#index", as: :units
  get "/unit", to: "units#show", as: :unit

  # Engineer routes
  get "/engineer", to: "engineers#show", as: :engineer

  # Locale switching
  post "locale/:locale", to: "locales#switch", as: :switch_locale

  # Theme switching
  post "theme/:theme", to: "themes#switch", as: :switch_theme
end
