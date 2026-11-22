class Dashboard::Organisations::WorkspacesController < Dashboard::OrganisationsController
  before_action :set_organisation, only: %i[ index ]

  def index
    @workspaces = @organisation.workspaces.order(name: :asc)
    @workspace_content = "dashboard/organisations/workspaces/index"
    render "dashboard/organisations/show" unless turbo_frame_request?
  end
end
