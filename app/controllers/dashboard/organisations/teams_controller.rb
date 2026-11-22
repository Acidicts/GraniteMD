class Dashboard::Organisations::TeamsController < Dashboard::OrganisationsController
  before_action :set_organisation, only: %i[ index show edit create update new ]

  def index
    @workspaces = @organisation.workspaces.order(name: :asc)
    @workspace_content = "dashboard/organisations/teams/index"
    render "dashboard/organisations/show" unless turbo_frame_request?
  end

  def show
  end

  def edit
  end

  def create
  end

  def update
  end

  def new
  end
end
