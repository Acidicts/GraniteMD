require 'rails_helper'

RSpec.describe "Admin::Superadmin::Jobs", type: :request do
  describe "GET /jobs" do
    it "renders the jobs page for a superadmin" do
      sign_in create(:user, role: :superadmin)

      get "/jobs"

      expect(response).to have_http_status(:success)
    end

    it "redirects an admin away from the jobs page" do
      sign_in create(:user, role: :admin)

      get "/jobs"

      expect(response).to redirect_to("/")
    end

    it "redirects guests to the login page" do
      get "/jobs"

      expect(response).to redirect_to("/login")
    end
  end
end
