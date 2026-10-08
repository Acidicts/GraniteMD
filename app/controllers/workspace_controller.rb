class WorkspaceController < ApplicationController
  def show
    workspace = Workspace.find_by(id: params[:id])
    return redirect_to dashboard_workspaces_path, alert: "We couldn't find that workspace" if workspace.nil?
    return redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace" unless workspace.users.exists?(current_user.id)
    @workspace = workspace

    render "workspace/show"
  end

  def update
    workspace = Workspace.find_by(id: params[:id])
    return redirect_to dashboard_workspaces_path, alert: "We couldn't find that workspace" if workspace.nil?
    return redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace" unless workspace.users.exists?(current_user.id)
    @workspace = workspace
  end

  def change_file
    page = Page.find_by(id: params[:id])
    return redirect_to dashboard_workspaces_path, alert: "We couldn't find that page" if page.nil?
    if params[:workspace_id].present? && page.folder.workspace_id.to_s != params[:workspace_id].to_s
      return redirect_to dashboard_workspaces_path, alert: "We couldn't find that page"
    end
    return redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace" unless page.workspace.users.exists?(current_user.id)

    render partial: "workspace/editor", locals: { page: page, workspace: page.workspace }
  end
  alias_method :changeFile, :change_file

  def new_file
    workspace = Workspace.find_by(id: params[:workspace_id])
    return redirect_to dashboard_workspaces_path, alert: "We couldn't find that workspace" if workspace.nil?
    return redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace" unless workspace.users.exists?(current_user.id)

    folder_id = params.dig(:page, :folder_id) || params[:folder_id]
    folder = workspace.folders.find_by(id: folder_id) if folder_id.present?
    if folder.nil? && folder_id.blank?
      # Blank workspace (or no location picked): reuse the first root
      # folder, creating a default one if none exists yet.
      folder = workspace.folders.where(parent_id: nil).order(:created_at).first ||
               workspace.folders.create(name: workspace.name)
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
    workspace = Workspace.find_by(id: params[:workspace_id])
    return redirect_to dashboard_workspaces_path, alert: "We couldn't find that workspace" if workspace.nil?
    return redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace" unless workspace.users.exists?(current_user.id)

    parent_id = params.dig(:folder, :parent_id) || params[:parent_id]
    parent = workspace.folders.find_by(id: parent_id) if parent_id.present?
    if parent.nil? && parent_id.present?
      return redirect_to workspace_path(workspace), alert: "We couldn't find that folder"
    end

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

  def find_authorized_page
    page = Page.find_by(id: params[:id])
    if page.nil?
      redirect_to dashboard_workspaces_path, alert: "We couldn't find that page"
      return nil
    end
    if params[:workspace_id].present? && page.folder.workspace_id.to_s != params[:workspace_id].to_s
      redirect_to dashboard_workspaces_path, alert: "We couldn't find that page"
      return nil
    end
    unless page.workspace.users.exists?(current_user.id)
      redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace"
      return nil
    end
    page
  end

  def sanitized_page_name(raw)
    raw.to_s.strip.sub(/\.(md|markdown)\z/i, "").strip
  end
end
