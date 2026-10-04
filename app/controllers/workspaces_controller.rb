class WorkspacesController < ApplicationController
  before_action :set_workspace, only: %i[ show edit update destroy ]

  # GET /workspaces
  def index
    @workspaces = Workspace.all
  end

  # GET /workspaces/1
  def show
  end

  # GET /workspaces/new
  def new
    @workspace = Workspace.new
  end

  # GET /workspaces/1/edit
  def edit
  end

  # POST /workspaces
  def create
    @workspace = Workspace.new(workspace_params)

    if @workspace.save
      redirect_to @workspace, notice: "Workspace was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /workspaces/1
  def update
    if @workspace.update(workspace_params)
      redirect_to @workspace, notice: "Workspace was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /workspaces/1
  def destroy
    @workspace.destroy!
    redirect_to workspaces_path, notice: "Workspace was successfully destroyed.", status: :see_other
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_workspace
    @workspace = Workspace.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def workspace_params
    params.require(:workspace).permit(:name)
  end
end
