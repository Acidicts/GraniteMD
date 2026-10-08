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
    end

    def new_users
      @users = []
      if params[:id].present?
        return unless Organisation.find(id: params[:id]).users.include?(current_user)
        organisation = Organisation.find_by(id: params[:id])
        @users = organisation.users if organisation&.users&.include?(current_user)
      end
      render partial: "dashboard/workspaces/turbo/new_workspace_organisation_users"
    end

    # GET /dashboard/workspaces/:id/edit
    def edit
    end

    # POST /dashboard/workspaces
    def create
      unless params[:organisation_id].nil? || Organisation.find(id: workspace_params[:organisation_id])&.users.include?(current_user)
        return redirect_to "You are not in this organisation"
      end
      @workspace = Workspace.new(workspace_params)
      @workspace.owner = current_user if @workspace.organisation_id.blank? && @workspace.owner_id.blank?

      if @workspace.save
        @workspace.users << @workspace.owner if @workspace.owner
        @workspace.users << current_user unless @workspace.users.include?(current_user)

        redirect_to dashboard_workspace_path(@workspace), notice: "Workspace was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    # PATCH/PUT /dashboard/workspaces/:id
    def update
      return unless @workspace&.owner == current_user
      if @workspace.update(workspace_params)
        redirect_to dashboard_workspace_path(@workspace), notice: "Workspace was successfully updated.", status: :see_other
      else
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
      @workspace = Workspace.find(params.expect(:id))
      return if @workspace.users.exists?(current_user.id)

      redirect_to dashboard_path
    end

    # Only allow a list of trusted parameters through.
    def workspace_params
      permitted = params.require(:workspace).permit(:name, :feature_set, :organisation_id, :owner_id)
      permitted[:organisation_id] = nil if permitted[:organisation_id].blank?
      permitted
    end
  end
end
