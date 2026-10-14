module Dashboard
  class WorkspacesController < DashboardController
    before_action :set_workspace, only: %i[ show edit update destroy ]

    # GET /dashboard/workspaces
    def index
      @workspaces = current_user.workspaces
    end

    # GET /dashboard/workspaces/:id
    def show
    end

    # GET /dashboard/workspaces/new
    def new
      @workspace = Workspace.new
      if params[:organisation].present?
        ident = params[:organisation].to_s
        # `new_dashboard_workspace_path(organisation: @organisation)` emits the
        # public_id via to_param, but accept a numeric id too.
        org = Organisation.find_by(id: ident) if ident.match?(/\A\d+\z/)
        org ||= Organisation.find_by("LOWER(public_id) = ?", ident.downcase)
        @workspace.organisation = org if org && org.users.exists?(current_user.id)
      end
      @org_locked = ActiveModel::Type::Boolean.new.cast(params[:org_locked]) && @workspace.organisation_id.present?
    end

    def new_users
      @users = []
      if params[:id].present?
        organisation = Organisation.find_by(id: params[:id])
        @users = organisation.users if organisation&.users&.include?(current_user)
      end
      render partial: "dashboard/workspaces/turbo/new_workspace_organisation_users"
    end

    # GET /dashboard/workspaces/:id/edit
    def edit
      @org_locked = false
    end

    # POST /dashboard/workspaces
    def create
      @workspace = Workspace.new(workspace_params)
      if @workspace.organisation_id.present?
        org = Organisation.find_by(id: @workspace.organisation_id)
        unless org&.users&.include?(current_user)
          return redirect_to dashboard_workspaces_path, alert: "You are not in this organisation"
        end
      end
      unless valid_workspace_owner?(@workspace)
        return redirect_to dashboard_workspaces_path, alert: "That owner is not a member of this workspace"
      end
      @workspace.owner = current_user if @workspace.organisation_id.blank? && @workspace.owner_id.blank?

      if @workspace.save
        @workspace.users << @workspace.owner if @workspace.owner
        @workspace.users << current_user unless @workspace.users.include?(current_user)

        redirect_to dashboard_workspace_path(@workspace), notice: "Workspace was successfully created."
      else
        @org_locked = false
        render :new, status: :unprocessable_content
      end
    end

    # PATCH/PUT /dashboard/workspaces/:id
    def update
      return unless @workspace&.owner == current_user
      unless authorized_workspace_change?(workspace_params)
        return redirect_to dashboard_workspaces_path, alert: "You are not allowed to make that change"
      end
      if @workspace.update(workspace_params)
        redirect_to dashboard_workspace_path(@workspace), notice: "Workspace was successfully updated.", status: :see_other
      else
        @org_locked = false
        render :edit, status: :unprocessable_content
      end
    end

    # DELETE /dashboard/workspaces/:id
    def destroy
      return unless @workspace&.owner == current_user
      @workspace.destroy!
      redirect_to dashboard_workspaces_path, notice: "Workspace was successfully destroyed.", status: :see_other
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_workspace
      @workspace = Workspace.find_by_id_or_public_id(params.expect(:public_id))
      if @workspace.nil?
        return redirect_to dashboard_workspaces_path, alert: "We couldn't find that workspace"
      end
      return if @workspace.users.exists?(current_user.id)

      redirect_to dashboard_path
    end

    # Only allow a list of trusted parameters through.
    def workspace_params
      permitted = params.require(:workspace).permit(:name, :feature_set, :organisation_id, :owner_id, :workspace_image)
      permitted[:organisation_id] = nil if permitted[:organisation_id].blank?
      permitted
    end

    # The form only ever offers organisation members (or nobody) as owner, so
    # a crafted owner_id outside that set must not stick. Personal workspaces
    # always end up owned by the creator (see #create).
    def valid_workspace_owner?(workspace)
      return true if workspace.owner_id.blank?
      return true if workspace.owner_id == current_user.id

      org = workspace.organisation
      org.present? && org.users.exists?(workspace.owner_id)
    end

    # Guards the two ids a crafted update could abuse: the workspace may only
    # move into an organisation the requester belongs to, and the new owner
    # must be the requester or a member of the resulting organisation.
    def authorized_workspace_change?(attrs)
      if attrs[:organisation_id].present?
        org = Organisation.find_by(id: attrs[:organisation_id])
        return false unless org&.users&.include?(current_user)
      end

      owner_id = attrs[:owner_id].presence&.to_i
      return true if owner_id.blank? || owner_id == current_user.id

      org = if attrs[:organisation_id].present?
        Organisation.find_by(id: attrs[:organisation_id])
      else
        @workspace.organisation
      end
      org.present? && org.users.exists?(owner_id)
    end
  end
end
