require 'rails_helper'

RSpec.describe "Workspace short URLs", type: :request do
  let!(:user) { create(:user) }

  before { sign_in user }

  def create_workspace(attributes = {})
    Workspace.create!({ name: "Engineering", feature_set: "personal" }.merge(attributes)).tap { |workspace| workspace.users << user }
  end

  describe "GET /workspace" do
    it "redirects to the dashboard workspaces list" do
      get "/workspace"
      expect(response).to redirect_to("/dashboard/workspaces")
    end
  end

  describe "GET /workspace/:id" do
    it "renders the workspace via WorkspaceController#show" do
      workspace = create_workspace
      get workspace_path(workspace)
      expect(response).to be_successful
    end

    it "redirects to the workspaces list when the workspace does not exist" do
      get "/workspace/0"
      expect(response).to redirect_to(dashboard_workspaces_path)
    end

    it "redirects to the workspaces list when the user is not a member" do
      other = create_workspace(name: "Stranger")
      other.users.delete(user)
      get workspace_path(other)
      expect(response).to redirect_to(dashboard_workspaces_path)
    end
  end
end
