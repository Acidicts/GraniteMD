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

  get  "signup"          => "dashboard/users#new"
  post "signup"          => "dashboard/users#create"
  get  "unique_username" => "dashboard/users#unique_username"
  get  "unique_email" => "dashboard/users#unique_email"

  resources :workspaces
  resources :passwords, param: :token

  get "/dashboard", to: "dashboard#index", as: :dashboard

  scope "/dashboard", as: "dashboard", module: "dashboard" do
    resources :users, only: %i[index edit update]

    get "you", to: "users#index"
    get "profile/edit", to: "users#edit"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
