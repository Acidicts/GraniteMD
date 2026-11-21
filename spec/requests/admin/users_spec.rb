require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  describe "GET /admin/users/:id" do
    it "returns http success for admin" do
      admin = create(:user, role: :admin)
      user = create(:user)

      sign_in admin
      get admin_user_path(user)

      expect(response).to have_http_status(:success)
    end

    it "returns http success for superadmin" do
      superadmin = create(:user, role: :superadmin)
      user = create(:user)

      sign_in superadmin
      get admin_user_path(user)

      expect(response).to have_http_status(:success)
    end

    it "redirects non-admin users" do
      sign_in create(:user, role: :user)
      user = create(:user)

      get admin_user_path(user)

      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /admin/users/new" do
    it "returns http success for admin" do
      sign_in create(:user, role: :admin)

      get new_admin_user_path

      expect(response).to have_http_status(:success)
    end

    it "returns http success for superadmin" do
      sign_in create(:user, role: :superadmin)

      get new_admin_user_path

      expect(response).to have_http_status(:success)
    end

    it "redirects non-admin users" do
      sign_in create(:user, role: :user)

      get new_admin_user_path

      expect(response).to have_http_status(:redirect)
    end
  end
end
