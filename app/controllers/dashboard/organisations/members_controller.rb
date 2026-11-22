class Dashboard::Organisations::MembersController < Dashboard::OrganisationsController
  before_action :set_organisation, only: %i[ index show invite ]

  def index
    @workspaces = @organisation.workspaces.order(name: :asc)
    @workspace_content = "dashboard/organisations/members/index"

    per_page = [ [ 50, (params[:paginator].to_s.strip.blank? ? 10 : params[:paginator]).to_i ].min, 1 ].max
    current_page = [ 1, params[:page].to_i ].max
    search_term = params[:search_term].to_s.strip

    members = @organisation.users.order(:username, :id)
    members = members.fuzzy_search(search_term)
    @members = members.offset((current_page - 1) * per_page)
                      .limit(per_page)

    if turbo_frame_request_id == "workspace_show_content-members"
      render partial: "dashboard/organisations/members/members_frame", layout: false
    else
      render "dashboard/organisations/show" unless turbo_frame_request?
    end
  end

  def show
    @workspaces = @organisation.workspaces.order(name: :asc)
    @workspace_content = "dashboard/organisations/members/show"
    render "dashboard/organisations/show" unless turbo_frame_request?
  end

  def invite
    @workspaces = @organisation.workspaces.order(name: :asc)
    @workspace_content = "dashboard/organisations/members/invite"
    render "dashboard/organisations/show" unless turbo_frame_request?
  end
end
