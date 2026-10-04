Rails.application.routes.draw do
  root "home#index", as: :home

  controller :home do
    get "faq"   => :faq,   as: :home_faq
    get "about" => :about, as: :home_about
    get "team"  => :team,  as: :home_team
  end

  controller :sessions do
    get    "login"  => :new
    post   "login"  => :create
    delete "logout" => :destroy
  end

  resources :passwords, param: :token, only: %i[ new create edit update ]

  get "signup"          => "dashboard/users#new"
  post "signup"          => "dashboard/users#create"
  # POST rather than GET so the request needs a CSRF token: a GET can be fired
  # cross-origin from any page, which turns this into a third-party email
  # lookup oracle.
  post "unique_username" => "dashboard/users#unique_username"
  post "unique_email"    => "dashboard/users#unique_email"

  resources :workspaces

  get "/dashboard", to: "dashboard#index", as: :dashboard

  scope "/dashboard", as: "dashboard", module: "dashboard" do
    resources :users, only: %i[index edit update]

    get "you", to: "users#index"
    get "profile/edit", to: "users#edit"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
