require "rails_helper"

RSpec.describe "Workspace access control", type: :request do
  let(:owner) { create(:user, email_address: "owner@example.com", username: "owneruser") }
  let(:outsider) { create(:user, email_address: "outsider@example.com", username: "outsideruser") }
  let!(:workspace) { Workspace.create!(name: "Engineering").tap { |w| w.users << owner } }

  describe "a member" do
    before { sign_in owner }

    it "reads the workspace" do
      get workspace_url(workspace)
      expect(response).to have_http_status(:success)
    end

    it "renames it" do
      patch workspace_url(workspace), params: { workspace: { name: "Renamed" } }
      expect(workspace.reload.name).to eq("Renamed")
    end

    it "destroys it" do
      expect { delete workspace_url(workspace) }.to change(Workspace, :count).by(-1)
    end
  end

  describe "a non-member" do
    before { sign_in outsider }

    it "is redirected away from show" do
      get workspace_url(workspace)
      expect(response).to redirect_to(dashboard_path)
    end

    it "cannot rename it" do
      patch workspace_url(workspace), params: { workspace: { name: "Pwned" } }

      expect(response).to redirect_to(dashboard_path)
      expect(workspace.reload.name).to eq("Engineering")
    end

    it "cannot destroy it" do
      expect { delete workspace_url(workspace) }.not_to change(Workspace, :count)
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "an anonymous visitor" do
    it "is sent to sign in rather than shown a workspace" do
      get workspace_url(workspace)

      expect(response).to redirect_to(login_path)
    end
  end

  it "lists only the workspaces the user belongs to" do
    sign_in outsider
    mine = Workspace.create!(name: "Mine").tap { |w| w.users << outsider }

    get workspaces_url

    expect(response.body).to include("workspace_#{mine.id}")
    expect(response.body).not_to include("workspace_#{workspace.id}")
  end
end
