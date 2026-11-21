require 'rails_helper'

RSpec.describe "Admin::OrganisationApplications", type: :request do
  describe "PATCH /admin/organisation-applications/:id/approve" do
    it "approves the application" do
      admin = create(:user, role: :admin)
      application = create(:organisation_application, status: :pending)

      sign_in admin
      patch approve_admin_organisation_application_path(application)

      expect(response).to have_http_status(:redirect)
      expect(application.reload.status).to eq("approved")
    end
  end

  describe "PATCH /admin/organisation-applications/:id/reject" do
    it "rejects the application" do
      admin = create(:user, role: :admin)
      application = create(:organisation_application, status: :pending)

      sign_in admin
      patch reject_admin_organisation_application_path(application)

      expect(response).to have_http_status(:redirect)
      expect(application.reload.status).to eq("rejected")
      expect(application.appeal_locked?).to be(false)
    end

    it "locks appeals when the application has been rejected before" do
      admin = create(:user, role: :admin)
      application = create(:organisation_application, status: :pending)

      sign_in admin
      patch reject_admin_organisation_application_path(application)
      application.update!(status: :pending)

      patch reject_admin_organisation_application_path(application)

      expect(response).to have_http_status(:redirect)
      expect(application.reload.status).to eq("rejected")
      expect(application.reload.appeal_locked?).to be(true)
    end
  end
end
