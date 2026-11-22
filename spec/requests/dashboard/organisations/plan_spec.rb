require 'rails_helper'

RSpec.describe "Dashboard::Organisations::Plan", type: :request do
  describe "GET /index" do
    it "returns http success" do
      user = create(:user)
      organisation = create(:organisation)
      organisation.users << user unless organisation.users.include?(user)

      sign_in user
      get dashboard_organisation_plan_index_path(organisation)

      expect(response).to have_http_status(:success)
    end
  end
end
