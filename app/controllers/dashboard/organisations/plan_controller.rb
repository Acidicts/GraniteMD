class Dashboard::Organisations::PlanController < Dashboard::OrganisationsController
  before_action :set_organisation, only: %i[ index update ]

  def index
    @workspaces = @organisation.workspaces.order(name: :asc)
    @workspace_content = "dashboard/organisations/plan/index"
    render "dashboard/organisations/show" unless turbo_frame_request?
  end

  def update
  end
end
