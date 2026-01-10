Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Devise authentication routes
  devise_for :users

  # Root path - Overview Dashboard
  root "dashboards#overview"

  # Dashboards routes
  get 'dashboards/overview', to: 'dashboards#overview', as: :overview_dashboard
  get 'dashboards/personal', to: 'dashboards#personal', as: :personal_dashboard

  # Teams routes
  get '/team', to: 'teams#show', as: :team

  # Admin routes
  namespace :admin do
    resources :technologies
    resources :quarters
    resources :users
    resources :teams
  end

  # Skill ratings management
  resources :skill_ratings do
    collection do
      post :copy_from_previous
    end
    member do
      post :submit
      post :approve
      post :reject
    end
  end

  # Action plans management
  resources :action_plans do
    member do
      post :complete
      post :pause
      post :resume
    end
  end

  # API routes for AJAX/Hotwire updates
  namespace :api do
    namespace :v1 do
      resources :metrics, only: [:index]
      resources :notifications, only: [:index, :create]
    end
  end
end
