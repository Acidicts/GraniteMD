class WorkspaceController < ApplicationController
  def show
    workspace = Workspace.find_by(id: params[:id])
    return redirect_to dashboard_workspaces_path, alert: "We couldn't find that workspace" if workspace.nil?
    return redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace" unless workspace.users.exists?(current_user.id)
    @workspace = workspace

    render "workspace/show"
  end
end
