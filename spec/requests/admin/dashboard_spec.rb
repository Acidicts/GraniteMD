require 'rails_helper'

RSpec.describe "Admin::Dashboards", type: :request do
  describe "GET /dashboard" do
    it "redirects to the admin overview" do
      sign_in create(:user, role: :admin)
      get admin_dashboard_path
      expect(response).to redirect_to(admin_overview_path)
    end
  end

  describe "GET /overview" do
    it "returns http success for admin" do
      sign_in create(:user, role: :admin)
      get admin_overview_path
      expect(response).to have_http_status(:success)
    end

    it "returns http success for superadmin" do
      sign_in create(:user, role: :superadmin)
      get admin_overview_path
      expect(response).to have_http_status(:success)
    end

    it "redirects non-admin users" do
      sign_in create(:user, role: :user)
      get admin_overview_path
      expect(response).to have_http_status(:redirect)
    end
  end
end
