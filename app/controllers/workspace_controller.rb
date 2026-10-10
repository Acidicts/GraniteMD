class WorkspaceController < ApplicationController
  before_action :set_workspace, only: %i[ show new_file new_folder ]

  def show
    @workspace.ensure_root_folder

    render "workspace/show"
  end

  def update
    @workspace = Workspace.find_by_id_or_public_id(params[:public_id] || params[:workspace_public_id])
    return redirect_to dashboard_workspaces_path, alert: "We couldn't find that workspace" if @workspace.nil?
    return redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace" unless @workspace.users.exists?(current_user.id)
  end

  def change_file
    page = Page.find_by(id: params[:id])
    return redirect_to dashboard_workspaces_path, alert: "We couldn't find that page" if page.nil?
    if params[:workspace_public_id].present? && !workspace_matches?(page.folder.workspace, params[:workspace_public_id])
      return redirect_to dashboard_workspaces_path, alert: "We couldn't find that page"
    end
    return redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace" unless page.workspace.users.exists?(current_user.id)

    render partial: "workspace/editor", locals: { page: page, workspace: page.workspace }
  end
  alias_method :changeFile, :change_file

  def new_file
    workspace = @workspace

    folder_id = params.dig(:page, :folder_id) || params[:folder_id]
    folder = workspace.folders.find_by(id: folder_id) if folder_id.present?
    if folder.nil?
      # A folder was picked but doesn't belong to this workspace: reject
      # instead of dropping the file into the root folder.
      if folder_id.present?
        return redirect_to workspace_path(workspace), alert: "Choose a folder for the new file"
      end
      # Single-root design: everything lives inside the workspace's one
      # root folder. Fall back to it (creating/consolidating if needed).
      folder = workspace.ensure_root_folder
    end
    if folder.nil? || !folder.persisted?
      return redirect_to workspace_path(workspace), alert: "Choose a folder for the new file"
    end

    # Explorer already appends ".md", so strip it (and whitespace) if typed.
    name = params.dig(:page, :name).to_s.strip.sub(/\.(md|markdown)\z/i, "").strip
    @workspace = workspace
    @page = folder.pages.build(name: name, body: "")

    if name.blank?
      return redirect_to workspace_path(workspace), alert: "File name can't be blank"
    end

    if @page.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to workspace_path(workspace), notice: "File created" }
      end
    else
      redirect_to workspace_path(workspace), alert: @page.errors.full_messages.to_sentence
    end
  end

  def new_folder
    workspace = @workspace

    parent_id = params.dig(:folder, :parent_id) || params[:parent_id]
    parent = workspace.folders.find_by(id: parent_id) if parent_id.present?
    if parent.nil? && parent_id.present?
      return redirect_to workspace_path(workspace), alert: "We couldn't find that folder"
    end
    # Single-root design: new folders always live inside the tree.
    # No parent given means "directly under the root folder".
    parent ||= workspace.ensure_root_folder

    name = params.dig(:folder, :name).to_s.strip
    @workspace = workspace
    @parent = parent
    @folder = workspace.folders.build(name: name, parent: parent)

    if name.blank?
      return redirect_to workspace_path(workspace), alert: "Folder name can't be blank"
    end

    if @folder.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to workspace_path(workspace), notice: "Folder created" }
      end
    else
      redirect_to workspace_path(workspace), alert: @folder.errors.full_messages.to_sentence
    end
  end

  def save_file
    page = find_authorized_page
    return if page.nil?

    @workspace = page.workspace
    @page = page

    # Rename flow (form sends page[name]) shares the same PATCH URL as
    # autosave (see routes). Dispatch on which param is present so both
    # helpers keep working despite sharing one path.
    if params.dig(:page, :name).present? || (params.key?(:page) && params[:page].key?(:name))
      name = sanitized_page_name(params.dig(:page, :name))
      if name.blank?
        return redirect_to workspace_path(@workspace), alert: "File name can't be blank"
      end

      if page.update(name: name)
        @page = page
        respond_to do |format|
          format.turbo_stream { render :rename_file }
          format.html { redirect_to workspace_path(@workspace), notice: "File renamed" }
          format.json { render json: { ok: true, id: page.id, name: page.name } }
        end
      else
        redirect_to workspace_path(@workspace), alert: page.errors.full_messages.to_sentence
      end
      return
    end

    body = params.dig(:page, :body)
    body = params[:body] if body.nil? && params.key?(:body)
    body = "" if body.nil?

    if page.update(body: body)
      respond_to do |format|
        format.json { render json: { ok: true, id: page.id, updated_at: page.updated_at } }
        format.turbo_stream { head :ok }
        format.html { redirect_to workspace_path(@workspace), notice: "File saved" }
      end
    else
      respond_to do |format|
        format.json { render json: { ok: false, errors: page.errors.full_messages }, status: :unprocessable_entity }
        format.html { redirect_to workspace_path(@workspace), alert: page.errors.full_messages.to_sentence }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  def rename_file
    page = find_authorized_page
    return if page.nil?

    name = sanitized_page_name(params.dig(:page, :name))
    if name.blank?
      return redirect_to workspace_path(page.workspace), alert: "File name can't be blank"
    end

    @workspace = page.workspace
    if page.update(name: name)
      @page = page
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to workspace_path(@workspace), notice: "File renamed" }
      end
    else
      redirect_to workspace_path(@workspace), alert: page.errors.full_messages.to_sentence
    end
  end

  def rename_folder
    folder = find_authorized_folder
    return if folder.nil?

    name = params.dig(:folder, :name).to_s.strip
    if name.blank?
      return redirect_to workspace_path(folder.workspace), alert: "Folder name can't be blank"
    end

    @workspace = folder.workspace
    if folder.update(name: name)
      @folder = folder
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to workspace_path(@workspace), notice: "Folder renamed" }
      end
    else
      redirect_to workspace_path(@workspace), alert: folder.errors.full_messages.to_sentence
    end
  end

  def delete_file
    page = find_authorized_page
    return if page.nil?

    @workspace = page.workspace
    @page_id = page.id
    page.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to workspace_path(@workspace), notice: "File deleted" }
    end
  end

  private

  def set_workspace
    @workspace = Workspace.find_by_id_or_public_id(params[:workspace_public_id])
    if @workspace.nil?
      redirect_to dashboard_workspaces_path, alert: "We couldn't find that workspace"
    elsif !@workspace.users.exists?(current_user.id)
      redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace"
    end
  end

  def workspace_matches?(workspace, identifier)
    return true if workspace.id.to_s == identifier.to_s
    workspace.public_id.present? && workspace.public_id.casecmp?(identifier.to_s)
  end

  def find_authorized_page
    page = Page.find_by(id: params[:id])
    if page.nil?
      redirect_to dashboard_workspaces_path, alert: "We couldn't find that page"
      return nil
    end
    if params[:workspace_public_id].present? && !workspace_matches?(page.folder.workspace, params[:workspace_public_id])
      redirect_to dashboard_workspaces_path, alert: "We couldn't find that page"
      return nil
    end
    unless page.workspace.users.exists?(current_user.id)
      redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace"
      return nil
    end
    page
  end

  def find_authorized_folder
    folder = Folder.find_by(id: params[:id])
    if folder.nil?
      redirect_to dashboard_workspaces_path, alert: "We couldn't find that folder"
      return nil
    end
    if params[:workspace_public_id].present? && !workspace_matches?(folder.workspace, params[:workspace_public_id])
      redirect_to dashboard_workspaces_path, alert: "We couldn't find that folder"
      return nil
    end
    unless folder.workspace.users.exists?(current_user.id)
      redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace"
      return nil
    end
    folder
  end

  def sanitized_page_name(raw)
    raw.to_s.strip.sub(/\.(md|markdown)\z/i, "").strip
  end
end
