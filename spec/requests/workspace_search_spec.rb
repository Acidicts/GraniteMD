require 'rails_helper'

# The quick switcher (Ctrl+K / Cmd+K) has two server ends: the page index
# the browser fuzzy-matches titles against, and the full-text search over
# the page bodies.
RSpec.describe "Workspace quick switcher", type: :request do
  let!(:user) { create(:user) }

  before { sign_in user }

  def create_workspace(attributes = {})
    Workspace.create!({ name: "Engineering", feature_set: "personal" }.merge(attributes)).tap do |workspace|
      workspace.users << user
    end
  end

  def upload_file(folder, name: "photo.png")
    create(:workspace_file, name: name, folder: folder).tap do |file|
      file.file.attach(io: StringIO.new("fake-image-bytes"), filename: name, content_type: "image/png")
    end
  end

  describe "GET /workspace/:workspace_public_id" do
    it "renders the quick switcher with the page index" do
      workspace = create_workspace
      create(:page, name: "Install guide", folder: workspace.folder)

      get workspace_path(workspace)

      expect(response).to be_successful
      expect(response.body).to include("workspace--quick-switcher")
      expect(response.body).to include("Install guide")
      expect(response.body).to include(search_workspace_pages_path(workspace))
      expect(response.body).to include(workspace_pages_index_path(workspace))
    end

    it "renders the quick switcher with the workspace files" do
      workspace = create_workspace
      upload_file(workspace.folder, name: "diagram.png")

      get workspace_path(workspace)

      expect(response).to be_successful
      expect(response.body).to include("diagram.png")
    end
  end

  describe "GET /workspace/:workspace_public_id/pages/index" do
    it "returns the page index the switcher matches titles against" do
      workspace = create_workspace
      page = create(:page, name: "Install guide", folder: workspace.folder)

      get workspace_pages_index_path(workspace)

      expect(response).to be_successful
      expect(response.parsed_body["pages"]).to include(
        "Install guide" => workspace_page_path(workspace, page)
      )
    end

    it "returns the workspace files next to the pages" do
      workspace = create_workspace
      file = upload_file(workspace.folder, name: "diagram.png")
      expected = [
        {
          "id" => file.id,
          "name" => "diagram.png",
          "folder" => "",
          "url" => workspace_file_path(workspace, file)
        }
      ]

      get workspace_pages_index_path(workspace)

      expect(response.parsed_body["files"]).to eq(expected)
    end

    it "leaves out the files of another workspace" do
      workspace = create_workspace
      other = create_workspace(name: "Other")
      upload_file(other.folder, name: "diagram.png")

      get workspace_pages_index_path(workspace)

      expect(response.parsed_body["files"]).to be_empty
    end

    it "redirects when the workspace does not exist" do
      get "/workspace/nope/pages/index"

      expect(response).to redirect_to(dashboard_workspaces_path)
    end

    it "redirects when the user is not a member of the workspace" do
      workspace = create_workspace
      workspace.users.delete(user)

      get workspace_pages_index_path(workspace)

      expect(response).to redirect_to(dashboard_workspaces_path)
    end
  end

  describe "GET /workspace/:workspace_public_id/pages/search" do
    it "finds the pages whose body holds the words" do
      workspace = create_workspace
      page = create(:page, name: "Notes", body: "The quickstart covers the panel setup", folder: workspace.folder)

      get search_workspace_pages_path(workspace), params: { q: "panel" }

      expect(response).to be_successful
      results = response.parsed_body["results"]
      expect(results.map { |result| result["id"] }).to eq([ page.id ])
      expect(results.first).to include(
        "name" => "Notes",
        "path" => "Notes",
        "url" => workspace_page_path(workspace, page)
      )
      expect(results.first["snippet"]).to include("panel setup")
    end

    it "finds a page by a word in its title" do
      workspace = create_workspace
      page = create(:page, name: "Install guide", body: "Nothing to see here", folder: workspace.folder)

      get search_workspace_pages_path(workspace), params: { q: "install" }

      expect(response.parsed_body["results"].map { |result| result["id"] }).to eq([ page.id ])
    end

    it "shows the folder a page sits in" do
      workspace = create_workspace
      folder = create(:folder, name: "Guides", workspace: workspace, parent: workspace.folder)
      page = create(:page, name: "Notes", body: "The quickstart covers the panel setup", folder: folder)

      get search_workspace_pages_path(workspace), params: { q: "panel" }

      expect(response.parsed_body["results"].first["path"]).to eq("Guides/Notes")
    end

    it "does not return the pages of another workspace" do
      workspace = create_workspace
      other = create_workspace(name: "Other")
      create(:page, name: "Notes", body: "The quickstart covers the panel setup", folder: other.folder)

      get search_workspace_pages_path(workspace), params: { q: "panel" }

      expect(response.parsed_body["results"]).to be_empty
    end

    it "returns nothing for a blank query" do
      workspace = create_workspace
      create(:page, name: "Notes", body: "The quickstart covers the panel setup", folder: workspace.folder)

      get search_workspace_pages_path(workspace), params: { q: "" }

      expect(response.parsed_body["results"]).to be_empty
    end

    it "redirects when the user is not a member of the workspace" do
      workspace = create_workspace
      workspace.users.delete(user)

      get search_workspace_pages_path(workspace), params: { q: "panel" }

      expect(response).to redirect_to(dashboard_workspaces_path)
    end
  end
end
