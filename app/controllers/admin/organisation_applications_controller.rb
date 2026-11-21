class Admin::OrganisationApplicationsController < Admin::DashboardController
  before_action :set_organisation_application

  def approve
    ActiveRecord::Base.transaction do
      previous_status = @organisation_application.status
      @organisation_application.update!(status: :approved)
      @organisation_application.audits.create!(
        user: current_user,
        action: "approve organisation application",
        details: {
          before: previous_status,
          after: @organisation_application.status
        }
      )
    end
    redirect_back fallback_location: admin_overview_path, notice: "Organisation application approved."
  end

  def reject
    @organisation_application.with_lock do
      previously_rejected = @organisation_application.audits.exists?(
        [ "action = ? and details->>'after' = ?", "reject organisation application", "rejected" ]
      )
      @organisation_application.update!(appeal_locked: true) if previously_rejected

      previous_status = @organisation_application.status
      @organisation_application.update!(status: :rejected)
      @organisation_application.audits.create!(
        user: current_user,
        action: "reject organisation application",
        details: {
          pitch: @organisation_application.pitch,
          before: previous_status,
          after: @organisation_application.status
        }
      )
    end
    redirect_back fallback_location: admin_overview_path, notice: "Organisation application rejected."
  end

  private

  def set_organisation_application
    @organisation_application = OrganisationApplication.find(params[:id])
  end
end
