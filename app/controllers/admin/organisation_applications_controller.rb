class Admin::OrganisationApplicationsController < Admin::DashboardController
  before_action :set_organisation_application

  def approve
    @organisation_application.update!(status: :approved)
    redirect_back fallback_location: admin_overview_path, notice: "Organisation application approved."
  end

  def reject
    @organisation_application.update!(status: :rejected)
    redirect_back fallback_location: admin_overview_path, notice: "Organisation application rejected."
  end

  private

  def set_organisation_application
    @organisation_application = OrganisationApplication.find(params[:id])
  end
end
