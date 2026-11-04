require 'rails_helper'

RSpec.describe "Admin::Superadmin::Dashboards", type: :request do
  describe "GET /dashboard" do
    it "returns http success for superadmin" do
      sign_in create(:user, role: :superadmin)
      get admin_superadmin_dashboard_path
      expect(response).to have_http_status(:success)
    end
    it "returns http redirect for admin" do
      sign_in create(:user, role: :admin)
      get admin_superadmin_dashboard_path
      expect(response).to have_http_status(:redirect)
    end
    it "redirect https forbidden" do
      sign_in create(:user, role: :user)
      get admin_superadmin_dashboard_path
      expect(response).to have_http_status(:redirect)
    end
  end
end
