Rails.application.routes.draw do
  # mount MissionControl::Jobs::Engine, at: "/jobs"
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
    post "/:workspace_public_id/files", action: :new_workspace_file, as: :workspace_files
    get "/:workspace_public_id/files/:id", action: :workspace_file, as: :workspace_file
    post "/:workspace_public_id/roadmaps", action: :new_roadmap, as: :workspace_roadmaps
    get "/:workspace_public_id/roadmaps/:id", action: :change_roadmap, as: :workspace_roadmap
    # Rename form and autosave share one PATCH endpoint (like pages);
    # two named routes keep both helpers working.
    patch "/:workspace_public_id/roadmaps/:id", action: :save_roadmap, as: :save_workspace_roadmap
    patch "/:workspace_public_id/roadmaps/:id", action: :save_roadmap, as: :rename_workspace_roadmap
    delete "/:workspace_public_id/roadmaps/:id", action: :delete_roadmap, as: :delete_workspace_roadmap
    # Categories hang off a roadmap rather than the workspace, so they live one
    # segment deeper: the roadmap id in the path is what the action authorizes
    # and what the new category is attached to.
    post "/:workspace_public_id/roadmaps/:id/catagories", action: :new_catagory, as: :workspace_roadmap_catagories
    # Items (roadmap_tasks) hang off the roadmap like categories do.
    post "/:workspace_public_id/roadmaps/:id/items", action: :new_roadmap_item, as: :workspace_roadmap_items
    # Drag-and-drop re-categorising hits this. The task id is in the path so the
    # action can scope the lookup to this roadmap.
    get "/:workspace_public_id/roadmaps/:id/items/overlay/:item_id", action: :get_roadmap_item, as: :get_workspace_roadmap_item
    get "/:workspace_public_id/roadmaps/:id/items/:item_id", action: :edit_roadmap_item, as: :edit_workspace_roadmap_item
    patch "/:workspace_public_id/roadmaps/:id/items/:item_id", action: :update_roadmap_item, as: :workspace_roadmap_item
    # The edit form and the drag/drop move share this one PATCH endpoint (as
    # pages do); two named routes keep both helpers working.
    patch "/:workspace_public_id/roadmaps/:id/items/:item_id", action: :update_roadmap_item, as: :update_workspace_roadmap_item
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
    resources :organisations, param: :public_id
    resources :users, only: %i[index edit update]

    get "you", to: "users#index"
    get "profile/edit", to: "users#edit"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
