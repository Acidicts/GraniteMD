Rails.application.routes.draw do
  root "home#index", as: :home

  controller :home do
    get "roadmap" => :roadmap, as: :home_roadmap
    get "faq"     => :faq,     as: :home_faq
    get "about"   => :about,   as: :home_about
    get "team"    => :team,    as: :home_team
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

  get "/dashboard", to: "dashboard#index", as: :dashboard

  get "/workspace", to: redirect("/dashboard/workspaces"), as: nil
  get "/workspace/:id", to: "workspace#show", as: :workspace
  get "/workspace/:workspace_id/pages/new", to: redirect { |params, _req| "/workspace/#{params[:workspace_id]}" }, as: :new_workspace_page
  post "/workspace/:workspace_id/pages", to: "workspace#new_file", as: :workspace_pages
  post "/workspace/:workspace_id/folders", to: "workspace#new_folder", as: :workspace_folders
  get "/workspace/:workspace_id/pages/:id", to: "workspace#change_file", as: :workspace_page
  patch "/workspace/:workspace_id/pages/:id", to: "workspace#save_file", as: :save_workspace_page
  # Same PATCH path as above (rename form + autosave share one endpoint;
  # WorkspaceController#save_file dispatches on page[name] vs page[body]).
  # Kept as a separate named route so `rename_workspace_page_path` keeps working.
  patch "/workspace/:workspace_id/pages/:id", to: "workspace#save_file", as: :rename_workspace_page
  delete "/workspace/:workspace_id/pages/:id", to: "workspace#delete_file", as: :delete_workspace_page

  scope "/dashboard", as: "dashboard", module: "dashboard" do
    get "/workspaces/new_users", to: "workspaces#new_users"
    resources :workspaces
    resources :users, only: %i[index edit update]

    get "you", to: "users#index"
    get "profile/edit", to: "users#edit"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
