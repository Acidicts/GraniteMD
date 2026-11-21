require 'rails_helper'

RSpec.describe "Dashboard::OrganisationApplications", type: :request do
  describe "POST /dashboard/organisations/appeal" do
    it "rejects appeals when the application is locked" do
      user = create(:user)
      application = create(:organisation_application, owner_id: user.id, status: :rejected, appeal_locked: true)

      sign_in user
      post appeal_dashboard_organisations_path, params: { id: application.id, new_pitch: "Updated pitch" }

      expect(response).to redirect_to(dashboard_organisations_path)
      expect(flash[:alert]).to eq("Your organisation application is unable to be appealed")
      expect(application.reload.status).to eq("rejected")
      expect(application.pitch).not_to eq("Updated pitch")
    end

    it "rejects appeals when the application is not rejected" do
      user = create(:user)
      application = create(:organisation_application, owner_id: user.id, status: :pending, appeal_locked: true)

      sign_in user
      post appeal_dashboard_organisations_path, params: { id: application.id, new_pitch: "Updated pitch" }

      expect(response).to redirect_to(dashboard_organisations_path)
      expect(flash[:alert]).to eq("Your organisation application is unable to be appealed")
      expect(application.reload.status).to eq("pending")
      expect(application.pitch).not_to eq("Updated pitch")
    end

    it "submits an appeal for a rejected application" do
      user = create(:user)
      application = create(:organisation_application, owner_id: user.id, status: :rejected, appeal_locked: false, pitch: "Original pitch")

      sign_in user
      post appeal_dashboard_organisations_path, params: { id: application.id, new_pitch: "  Updated pitch  " }

      expect(response).to redirect_to(dashboard_organisations_path)
      expect(flash[:notice]).to eq("Appeal submitted.")
      application.reload
      expect(application.status).to eq("pending")
      expect(application.pitch).to eq("Updated pitch")
    end

    it "rejects an empty appeal pitch" do
      user = create(:user)
      application = create(:organisation_application, owner_id: user.id, status: :rejected, appeal_locked: false, pitch: "Original pitch")

      sign_in user
      post appeal_dashboard_organisations_path, params: { id: application.id, new_pitch: "   " }

      expect(response).to redirect_to(dashboard_organisations_path)
      expect(flash[:alert]).to eq("Your appeal pitch is empty, please provide appeal pitch")
      application.reload
      expect(application.status).to eq("rejected")
      expect(application.pitch).to eq("Original pitch")
    end
  end
end
