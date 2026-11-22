require 'rails_helper'

RSpec.describe "Dashboard::Organisations::Members", type: :request do
  describe "GET /index" do
    it "returns http success" do
      user = create(:user)
      organisation = create(:organisation)
      organisation.users << user unless organisation.users.include?(user)

      sign_in user
      get dashboard_organisation_members_path(organisation)

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /invite" do
    it "returns http success" do
      user = create(:user)
      organisation = create(:organisation)
      organisation.users << user unless organisation.users.include?(user)

      sign_in user
      get invite_dashboard_organisation_members_path(organisation)

      expect(response).to have_http_status(:success)
    end
  end
end
