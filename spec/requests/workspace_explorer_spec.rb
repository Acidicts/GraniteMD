require 'rails_helper'

RSpec.describe "Workspace explorer (verification)", type: :request do
  let!(:user) { create(:user) }
  before { sign_in user }

  it "renders folders and pages on show and serves a page via change_file" do
    workspace = Workspace.create!(name: "Explorer", feature_set: "personal")
    workspace.users << user
    root = Folder.create!(name: "Guides", workspace: workspace)
    sub = Folder.create!(name: "Setup", workspace: workspace, parent: root)
    install = Page.create!(name: "install", body: "hi", folder: root)
    Page.create!(name: "config", body: "cfg", folder: sub)

    get workspace_path(workspace)
    expect(response).to be_successful
    expect(response.body).to include("Guides")
    expect(response.body).to include("Setup")
    expect(response.body).to include("install")
    expect(response.body).to include("workspace--file-explorer")

    get workspace_page_path(workspace, install)
    expect(response).to be_successful
    expect(response.body).to include("workspace-editor")
  end

  describe "POST /workspace/:workspace_id/pages (new_file)" do
    let!(:workspace) do
      Workspace.create!(name: "Explorer", feature_set: "personal").tap { |ws| ws.users << user }
    end
    let!(:folder) { Folder.create!(name: "Guides", workspace: workspace) }

    it "creates the page in the folder and answers turbo-stream + html" do
      expect {
        post workspace_pages_path(workspace),
             params: { page: { name: "install", folder_id: folder.id } },
             as: :turbo_stream
      }.to change { folder.pages.count }.by(1)

      expect(response).to be_successful
      expect(response.body).to include("install")
      expect(response.body).to include("workspace-editor")
      expect(folder.pages.last.body).to eq("")

      expect {
        post workspace_pages_path(workspace),
             params: { page: { name: "plain", folder_id: folder.id } }
      }.to change { folder.pages.count }.by(1)
      expect(response).to redirect_to(workspace_path(workspace))
    end

    it "strips a typed .md suffix and rejects blank names" do
      post workspace_pages_path(workspace),
           params: { page: { name: "notes.md", folder_id: folder.id } }
      expect(folder.pages.last.name).to eq("notes")

      expect {
        post workspace_pages_path(workspace),
             params: { page: { name: "   ", folder_id: folder.id } }
      }.not_to change { Page.count }
      expect(response).to redirect_to(workspace_path(workspace))
    end

    it "rejects folders from other workspaces and strangers" do
      other = Workspace.create!(name: "Other", feature_set: "personal")
      foreign = Folder.create!(name: "Elsewhere", workspace: other)

      expect {
        post workspace_pages_path(workspace),
             params: { page: { name: "sneaky", folder_id: foreign.id } }
      }.not_to change { Page.count }

      stranger = create(:user, username: "stranger", email_address: "stranger@example.com")
      delete logout_path
      sign_in stranger
      expect {
        post workspace_pages_path(workspace),
             params: { page: { name: "nope", folder_id: folder.id } }
      }.not_to change { Page.count }
      expect(response).to redirect_to(dashboard_workspaces_path)
    end
  end

  describe "blank workspace (no folders)" do
    let!(:workspace) do
      Workspace.create!(name: "Blank", feature_set: "personal").tap { |ws| ws.users << user }
    end

    it "offers a New file button in the empty state" do
      get workspace_path(workspace)
      expect(response).to be_successful
      expect(response.body).to include("No files yet")
      expect(response.body).to include("new-page-form-root")
      expect(response.body).to include("showNewFileForm")
    end

    it "creates a default folder and the page when no folder is given" do
      expect {
        post workspace_pages_path(workspace), params: { page: { name: "first" } }
      }.to change { Folder.count }.by(1).and change { Page.count }.by(1)
      expect(response).to redirect_to(workspace_path(workspace))

      folder = workspace.folders.first
      expect(folder.parent_id).to be_nil
      expect(folder.pages.first.name).to eq("first")
    end

    it "reuses the existing root folder instead of creating another" do
      existing = Folder.create!(name: "Docs", workspace: workspace)
      expect {
        post workspace_pages_path(workspace), params: { page: { name: "second" } }
      }.not_to change { Folder.count }
      expect(existing.pages.last.name).to eq("second")
    end
  end

  describe "rename and delete pages" do
    let!(:workspace) do
      Workspace.create!(name: "Renamer", feature_set: "personal").tap { |ws| ws.users << user }
    end
    let!(:folder) { Folder.create!(name: "Docs", workspace: workspace) }
    let!(:page) { Page.create!(name: "draft", body: "hi", folder: folder) }

    it "shows rename/delete controls on each page row" do
      get workspace_path(workspace)
      expect(response).to be_successful
      expect(response.body).to include("workspace-page-#{page.id}")
      expect(response.body).to include("showRenameForm")
      expect(response.body).to include("Rename draft")
      expect(response.body).to include(delete_workspace_page_path(workspace, page))
    end

    it "renames via turbo-stream and html, stripping .md" do
      patch rename_workspace_page_path(workspace, page),
            params: { page: { name: "final.md" } }, as: :turbo_stream
      expect(response).to be_successful
      expect(page.reload.name).to eq("final")
      expect(response.body).to include("workspace-page-#{page.id}")
      expect(response.body).to include("final")

      patch rename_workspace_page_path(workspace, page),
            params: { page: { name: "renamed" } }
      expect(response).to redirect_to(workspace_path(workspace))
      expect(page.reload.name).to eq("renamed")
    end

    it "rejects blank names and guards" do
      patch rename_workspace_page_path(workspace, page), params: { page: { name: "  " } }
      expect(response).to redirect_to(workspace_path(workspace))
      expect(page.reload.name).to eq("draft")

      other = Workspace.create!(name: "Other", feature_set: "personal")
      get workspace_page_path(other, page)
      expect(response).to redirect_to(dashboard_workspaces_path)

      stranger = create(:user, username: "renamer_stranger", email_address: "renamer_stranger@example.com")
      delete logout_path
      sign_in stranger
      patch rename_workspace_page_path(workspace, page), params: { page: { name: "hijacked" } }
      expect(response).to redirect_to(dashboard_workspaces_path)
      expect(page.reload.name).to eq("draft")
    end

    it "deletes via turbo-stream and html" do
      delete delete_workspace_page_path(workspace, page), as: :turbo_stream
      expect(response).to be_successful
      expect(response.body).to include(%(turbo-stream action="remove" target="workspace-page-#{page.id}"))
      expect(response.body).to include("workspace-editor")
      expect(Page.exists?(page.id)).to be false

      doomed = Page.create!(name: "temp", folder: folder)
      expect {
        delete delete_workspace_page_path(workspace, doomed)
      }.to change { Page.count }.by(-1)
      expect(response).to redirect_to(workspace_path(workspace))
    end

    it "rejects deleting other workspaces' pages and strangers" do
      other = Workspace.create!(name: "Other", feature_set: "personal")
      foreign = Folder.create!(name: "Elsewhere", workspace: other)
      foreign_page = Page.create!(name: "nope", folder: foreign)

      expect {
        delete delete_workspace_page_path(workspace, foreign_page)
      }.not_to change { Page.count }

      stranger = create(:user, username: "deleter_stranger", email_address: "deleter_stranger@example.com")
      delete logout_path
      sign_in stranger
      expect {
        delete delete_workspace_page_path(workspace, page)
      }.not_to change { Page.count }
      expect(response).to redirect_to(dashboard_workspaces_path)
    end
  end
end
