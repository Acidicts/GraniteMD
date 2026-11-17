class Admin::DashboardController < ApplicationController
  layout "admin/admin"

  before_action :require_admin

  def index; end

  def overview
    @storage_used    = ActiveStorage::Blob.sum(:byte_size)
    @storage_limit   = ENV.fetch("STORAGE_LIMIT_BYTES", 15.gigabytes).to_i
    @storage_percent = (@storage_used * 100.0 / @storage_limit).round(3).clamp(0, 100)

    @queued_jobs     = SolidQueue::ReadyExecution.count
    @failed_jobs     = SolidQueue::FailedExecution.count
    @active_sessions = Session.where(last_seen_at: 15.minutes.ago..).count

    @pending_applications       = OrganisationApplication.pending.order(:created_at).limit(10)
    @pending_applications_count = OrganisationApplication.pending.count
    @application_owners         = User.where(id: @pending_applications.map(&:owner_id)).index_by(&:id)

    @stats = [ [ User.count, User.where(created_at: 7.days.ago..).count ], [ Workspace.count, Workspace.where.not(organisation_id: nil).count ], [ Page.count, Page.where(created_at: 7.days.ago..).count ], [ OrganisationApplication.where(status: :pending).count, OrganisationApplication.where(status: :pending).order(created_at: :asc).first ] ]
  end

  def users; end

  def pages; end

  def activity; end

  def settings; end

  private

  def require_admin
    return if current_user&.admin?

    redirect_to home_path, alert: "You are not authorised to do this."
  end

  def require_superadmin
    return if current_user&.superadmin?

    redirect_to home_path, alert: "You are not authorised to do this."
  end
end
