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

  # Workspace file explorer (WorkspaceController): show, file/folder
  # creation, rename/autosave and deletion all live under /workspace.
  scope "/workspace", controller: "workspace" do
    get "/", to: redirect("/dashboard/workspaces"), as: nil
    get "/:workspace_public_id", action: :show, as: :workspace
    get "/:workspace_public_id/pages/new", to: redirect { |params, _req| "/workspace/#{params[:workspace_public_id]}" }, as: :new_workspace_page
    post "/:workspace_public_id/pages", action: :new_file, as: :workspace_pages
    post "/:workspace_public_id/folders", action: :new_folder, as: :workspace_folders
    patch "/:workspace_public_id/folders/:id", action: :rename_folder, as: :rename_workspace_folder
    get "/:workspace_public_id/pages/:id", action: :change_file, as: :workspace_page
    patch "/:workspace_public_id/pages/:id", action: :save_file, as: :save_workspace_page
    # Same PATCH path as above (rename form + autosave share one endpoint;
    # WorkspaceController#save_file dispatches on page[name] vs page[body]).
    # Kept as a separate named route so `rename_workspace_page_path` keeps working.
    patch "/:workspace_public_id/pages/:id", action: :save_file, as: :rename_workspace_page
    delete "/:workspace_public_id/pages/:id", action: :delete_file, as: :delete_workspace_page
  end

  scope "/dashboard", as: "dashboard", module: "dashboard" do
    get "/workspaces/new_users", to: "workspaces#new_users"
    resources :workspaces, param: :public_id
    resources :users, only: %i[index edit update]

    get "you", to: "users#index"
    get "profile/edit", to: "users#edit"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
