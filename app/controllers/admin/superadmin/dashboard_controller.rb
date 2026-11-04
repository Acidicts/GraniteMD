class Admin::Superadmin::DashboardController < Admin::DashboardController
  before_action :require_superadmin
end
