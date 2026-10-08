require "rails_helper"

RSpec.describe "Workspace access control", type: :request do
  let(:owner)    { create(:user, email_address: "owner@example.com",    username: "owneruser") }
  let(:member)   { create(:user, email_address: "member@example.com",   username: "memberuser") }
  let(:outsider) { create(:user, email_address: "outsider@example.com", username: "outsideruser") }

  let!(:workspace) do
    Workspace.create!(name: "Engineering", feature_set: :personal, owner: owner).tap do |w|
      w.users << owner
      w.users << member
    end
  end

  describe "a owner" do
    before { sign_in owner }

    it "reads the workspace" do
      get dashboard_workspace_url(workspace)
      expect(response).to have_http_status(:success)
    end

    it "renames it" do
      patch dashboard_workspace_url(workspace), params: { workspace: { name: "Renamed" } }
      expect(workspace.reload.name).to eq("Renamed")
    end

    it "destroys it" do
      expect { delete dashboard_workspace_url(workspace) }.to change(Workspace, :count).by(-1)
    end
  end

  describe "a member" do
    before { sign_in member }

    it "reads the workspace" do
      get dashboard_workspace_url(workspace)
      expect(response).to have_http_status(:success)
    end

    it "renames it" do
      patch dashboard_workspace_url(workspace), params: { workspace: { name: "Renamed" } }
      expect(workspace.reload.name).to eq("Engineering")
    end

    it "destroys it" do
      expect { delete dashboard_workspace_url(workspace) }.to change(Workspace, :count).by(0)
    end
  end

  describe "a non-member" do
    before { sign_in outsider }

    it "is redirected away from show" do
      get dashboard_workspace_url(workspace)
      expect(response).to redirect_to(dashboard_path)
    end

    it "cannot rename it" do
      patch dashboard_workspace_url(workspace), params: { workspace: { name: "Pwned" } }

      expect(response).to redirect_to(dashboard_path)
      expect(workspace.reload.name).to eq("Engineering")
    end

    it "cannot destroy it" do
      expect { delete dashboard_workspace_url(workspace) }.not_to change(Workspace, :count)
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "an anonymous visitor" do
    it "is sent to sign in rather than shown a workspace" do
      get dashboard_workspace_url(workspace)

      expect(response).to redirect_to(login_path)
    end
  end

  it "lists only the workspaces the user belongs to" do
    sign_in outsider
    mine = Workspace.create!(name: "Mine", feature_set: :personal).tap { |w| w.users << outsider }

    get dashboard_workspaces_url

    expect(response.body).to include("workspace_#{mine.id}")
    expect(response.body).not_to include("workspace_#{workspace.id}")
  end
end
