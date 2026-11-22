class Dashboard::Organisations::LimitsController < Dashboard::OrganisationsController
  before_action :set_organisation, only: %i[ index update ]

  def index
    @workspaces = @organisation.workspaces.order(name: :asc)
    @workspace_content = "dashboard/organisations/limits/index"
    render "dashboard/organisations/show" unless turbo_frame_request?
  end

  def update
  end
end
