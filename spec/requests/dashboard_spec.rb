require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  describe "GET /index" do
    it "returns http success" do
      sign_in create(:user)
      get dashboard_path
      expect(response).to have_http_status(:success)
    end
  end
end
