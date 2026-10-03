Rails.application.routes.draw do
  get "/", to: "home#index", as: "home"
  get "/faq", to: "home#faq", as: "home_faq"
  get "/about", to: "home#about", as: "home_about"
  get "/team", to: "home#team", as: "home_team"

  get "/dashboard", to: "dashboard#index", as: "dashboard"

  resources :workspaces

  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check
end
