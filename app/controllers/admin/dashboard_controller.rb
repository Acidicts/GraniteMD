class Admin::DashboardController < ApplicationController
  before_action :require_admin

  def index; end

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
