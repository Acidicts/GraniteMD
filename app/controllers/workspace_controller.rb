class WorkspaceController < ApplicationController
  before_action :set_workspace, only: %i[ show new_file new_workspace_file new_roadmap new_folder ]

  def show
    @workspace.ensure_root_folder

    render "workspace/show"
  end

  def update
    @workspace = Workspace.find_by_id_or_public_id(params[:public_id] || params[:workspace_public_id])
    return redirect_to dashboard_workspaces_path, alert: "We couldn't find that workspace" if @workspace.nil?
    redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace" unless @workspace.users.exists?(current_user.id)
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

  def workspace_file
    workspace_file = WorkspaceFile.find_by(id: params[:id])
    return redirect_to dashboard_workspaces_path, alert: "We couldn't find that file" if workspace_file.nil?
    if params[:workspace_public_id].present? && !workspace_matches?(workspace_file.folder.workspace, params[:workspace_public_id])
      return redirect_to dashboard_workspaces_path, alert: "We couldn't find that file"
    end
    return redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace" unless workspace_file.workspace.users.exists?(current_user.id)

    render partial: "workspace/file_preview", locals: { workspace_file: workspace_file, workspace: workspace_file.workspace }
  end

  def change_roadmap
    roadmap = Roadmap.find_by(id: params[:id])
    return redirect_to dashboard_workspaces_path, alert: "We couldn't find that roadmap" if roadmap.nil?
    if params[:workspace_public_id].present? && !workspace_matches?(roadmap.folder.workspace, params[:workspace_public_id])
      return redirect_to dashboard_workspaces_path, alert: "We couldn't find that roadmap"
    end
    return redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace" unless roadmap.workspace.users.exists?(current_user.id)

    @categories = roadmap.roadmap_catagory

    render partial: "workspace/roadmap_editor", locals: { roadmap: roadmap, workspace: roadmap.workspace }
  end

  def new_file
    workspace = @workspace

    folder_id = params.dig(:page, :folder_id) || params[:folder_id]
    folder = workspace.folders.find_by(id: folder_id) if folder_id.present?
    if folder.nil?
      if folder_id.present?
        return redirect_to workspace_path(workspace), alert: "Choose a folder for the new file"
      end
      folder = workspace.ensure_root_folder
    end
    if folder.nil? || !folder.persisted?
      return redirect_to workspace_path(workspace), alert: "Choose a folder for the new file"
    end

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

  def new_workspace_file
    workspace = @workspace

    folder_id = params.dig(:workspace_file, :folder_id) || params[:folder_id]
    folder = workspace.folders.find_by(id: folder_id) if folder_id.present?
    if folder.nil?
      if folder_id.present?
        return redirect_to workspace_path(workspace), alert: "Choose a folder for the upload"
      end
      folder = workspace.ensure_root_folder
    end
    if folder.nil? || !folder.persisted?
      return redirect_to workspace_path(workspace), alert: "Choose a folder for the upload"
    end

    uploaded = params.dig(:workspace_file, :file)
    if uploaded.blank?
      return redirect_to workspace_path(workspace), alert: "Choose a file to upload"
    end

    name = params.dig(:workspace_file, :name).to_s.strip
    name = uploaded.original_filename.to_s.strip if name.blank?

    @workspace = workspace
    @workspace_file = folder.workspace_files.build(name: name)
    @workspace_file.file.attach(uploaded)

    if @workspace_file.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to workspace_path(workspace), notice: "File uploaded" }
      end
    else
      redirect_to workspace_path(workspace), alert: @workspace_file.errors.full_messages.to_sentence
    end
  end

  def new_roadmap
    workspace = @workspace

    folder_id = params.dig(:roadmap, :folder_id) || params[:folder_id]
    folder = workspace.folders.find_by(id: folder_id) if folder_id.present?
    if folder.nil?
      if folder_id.present?
        return redirect_to workspace_path(workspace), alert: "Choose a folder for the new roadmap"
      end
      folder = workspace.ensure_root_folder
    end
    if folder.nil? || !folder.persisted?
      return redirect_to workspace_path(workspace), alert: "Choose a folder for the new roadmap"
    end

    name = params.dig(:roadmap, :name).to_s.strip
    @workspace = workspace
    @roadmap = folder.roadmaps.build(name: name, body: "")

    if name.blank?
      return redirect_to workspace_path(workspace), alert: "Roadmap name can't be blank"
    end

    if @roadmap.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to workspace_path(workspace), notice: "Roadmap created" }
      end
    else
      redirect_to workspace_path(workspace), alert: @roadmap.errors.full_messages.to_sentence
    end
  end

  def new_catagory
    roadmap = find_authorized_roadmap
    return if roadmap.nil?

    name = params.dig(:roadmap_catagory, :name).to_s.strip
    @workspace = roadmap.workspace
    @roadmap = roadmap
    @roadmap_catagory = RoadmapCatagory.new(roadmap: roadmap, name: name)

    if name.blank?
      @roadmap_catagory.errors.add(:name, "can't be blank")
      return render_roadmap_editor(roadmap)
    end

    if @roadmap_catagory.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to workspace_roadmap_path(@workspace, roadmap), notice: "Catagory created" }
      end
    else
      render_roadmap_editor(roadmap)
    end
  end

  def new_roadmap_item
    roadmap = find_authorized_roadmap
    return if roadmap.nil?

    @workspace = roadmap.workspace
    @roadmap = roadmap
    @roadmap_task = RoadmapTask.new(roadmap: roadmap,
                                    header: params.dig(:roadmap_task, :header).to_s.strip,
                                    body: params.dig(:roadmap_task, :body).to_s.strip)
    @roadmap_task.assignee = current_user

    catagory = authorized_item_catagory(roadmap)
    if catagory.nil?
      @roadmap_task.errors.add(:category, "must be a catagory on this roadmap")
      return render_roadmap_editor(roadmap)
    end
    @roadmap_task.category = catagory.id
    @roadmap_catagory = catagory

    if @roadmap_task.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to workspace_roadmap_path(@workspace, roadmap), notice: "Item created" }
      end
    else
      render_roadmap_editor(roadmap)
    end
  end

  def edit_roadmap_item
    roadmap = find_authorized_roadmap
    return if roadmap.nil?

    task = roadmap.roadmap_tasks.find_by(id: params[:item_id])
    if task.nil?
      return redirect_to workspace_roadmap_path(roadmap.workspace, roadmap), alert: "We couldn't find that item"
    end

    @workspace = roadmap.workspace
    @roadmap = roadmap
    @roadmap_task = task

    render_edit_form(task, roadmap)
  end

  def update_roadmap_item
    roadmap = find_authorized_roadmap
    return if roadmap.nil?

    task = roadmap.roadmap_tasks.find_by(id: params[:item_id])
    return render_item_update_error(roadmap, "We couldn't find that item") if task.nil?

    attributes = task_update_attributes(roadmap)
    return if attributes.nil?

    if task.update(attributes)
      @roadmap_task = task
      respond_to do |format|
        format.json { render json: { ok: true, id: task.id, catagory_id: task.category } }
        format.turbo_stream
        format.html { redirect_to workspace_roadmap_path(roadmap.workspace, roadmap), notice: "Item updated" }
      end
    else
      @workspace = roadmap.workspace
      @roadmap = roadmap
      @roadmap_task = task
      render_edit_form(task, roadmap, status: :unprocessable_content)
    end
  end

  def new_folder
    workspace = @workspace

    parent_id = params.dig(:folder, :parent_id) || params[:parent_id]
    parent = workspace.folders.find_by(id: parent_id) if parent_id.present?
    if parent.nil? && parent_id.present?
      return redirect_to workspace_path(workspace), alert: "We couldn't find that folder"
    end

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
        format.json { render json: { ok: false, errors: page.errors.full_messages }, status: :unprocessable_content }
        format.html { redirect_to workspace_path(@workspace), alert: page.errors.full_messages.to_sentence }
        format.turbo_stream { head :unprocessable_content }
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

  def save_roadmap
    roadmap = find_authorized_roadmap
    return if roadmap.nil?

    @workspace = roadmap.workspace
    @roadmap = roadmap

    if params.key?(:roadmap) && params[:roadmap].key?(:name)
      name = params.dig(:roadmap, :name).to_s.strip
      if name.blank?
        return redirect_to workspace_path(@workspace), alert: "Roadmap name can't be blank"
      end

      if roadmap.update(name: name)
        @roadmap = roadmap
        respond_to do |format|
          format.turbo_stream { render :rename_roadmap }
          format.html { redirect_to workspace_path(@workspace), notice: "Roadmap renamed" }
        end
      else
        redirect_to workspace_path(@workspace), alert: roadmap.errors.full_messages.to_sentence
      end
      return
    end

    body = params.dig(:roadmap, :body)
    body = params.dig(:page, :body) if body.nil?
    body = params[:body] if body.nil? && params.key?(:body)
    body = "" if body.nil?

    if roadmap.update(body: body)
      respond_to do |format|
        format.json { render json: { ok: true, id: roadmap.id, updated_at: roadmap.updated_at } }
        format.turbo_stream { head :ok }
        format.html { redirect_to workspace_path(@workspace), notice: "Roadmap saved" }
      end
    else
      respond_to do |format|
        format.json { render json: { ok: false, errors: roadmap.errors.full_messages }, status: :unprocessable_content }
        format.html { redirect_to workspace_path(@workspace), alert: roadmap.errors.full_messages.to_sentence }
        format.turbo_stream { head :unprocessable_content }
      end
    end
  end

  def delete_roadmap
    roadmap = find_authorized_roadmap
    return if roadmap.nil?

    @workspace = roadmap.workspace
    @roadmap_id = roadmap.id
    roadmap.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to workspace_path(@workspace), notice: "Roadmap deleted" }
    end
  end

  private

  def render_edit_form(task, roadmap, status: :ok)
    render partial: "workspace/files/forms/edit_roadmap_item",
           locals: { workspace: roadmap.workspace, roadmap: roadmap, roadmap_task: task },
           formats: [ :html ],
           status: status
  end

  def render_roadmap_editor(roadmap)
    @categories = roadmap.roadmap_catagory.reload

    respond_to do |format|
      format.turbo_stream do
        render partial: "workspace/roadmap_editor",
               locals: { roadmap: roadmap, workspace: roadmap.workspace },
               formats: [ :html ]
      end
      format.html do
        redirect_to workspace_roadmap_path(roadmap.workspace, roadmap),
                    alert: @roadmap_catagory.errors.full_messages.to_sentence
      end
    end
  end

  def authorized_item_catagory(roadmap)
    id = params.dig(:roadmap_task, :category).to_i
    return nil unless id.positive?

    roadmap.roadmap_catagory.find_by(id: id)
  end

  def task_update_attributes(roadmap)
    permitted = params.fetch(:roadmap_task, ActionController::Parameters.new)
                      .permit(:header, :body, :category_index, :assignee_id)
    attributes = permitted.to_h.symbolize_keys
    attributes.delete_if { |_, value| value.nil? }
    if attributes.key?(:assignee_id)
      assignee = authorized_assignee(roadmap)
      if assignee.nil? && params.dig(:roadmap_task, :assignee_id).present?
        render_item_update_error(roadmap, "must be someone in this workspace")
        return nil
      end
      return attributes.except(:assignee_id).merge(assignee: assignee)
    end
    return attributes unless attributes.key?(:category_index)

    catagory = catagory_at_index(roadmap)
    if catagory.nil?
      render_item_update_error(roadmap, "must be a catagory on this roadmap")
      return nil
    end

    attributes.merge(category: catagory.id).except(:category_index)
  end

  def catagory_at_index(roadmap)
    raw = params.dig(:roadmap_task, :category_index).to_s
    return nil unless raw.match?(/\A\d+\z/)

    roadmap.roadmap_catagory[raw.to_i]
  end

  def authorized_assignee(roadmap)
    raw = params.dig(:roadmap_task, :assignee_id).to_s
    return nil if raw.blank?

    return nil unless raw.match?(/\A\d+\z/)

    roadmap.workspace.users.find_by(id: raw.to_i)
  end

  def render_item_update_error(roadmap, message)
    respond_to do |format|
      format.json { render json: { ok: false, errors: [ message ] }, status: :unprocessable_content }
      format.turbo_stream { head :unprocessable_content }
      format.html { redirect_to workspace_roadmap_path(roadmap.workspace, roadmap), alert: message }
    end
  end

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

  def find_authorized_roadmap
    roadmap = Roadmap.find_by(id: params[:id])
    if roadmap.nil?
      redirect_to dashboard_workspaces_path, alert: "We couldn't find that roadmap"
      return nil
    end
    if params[:workspace_public_id].present? && !workspace_matches?(roadmap.folder.workspace, params[:workspace_public_id])
      redirect_to dashboard_workspaces_path, alert: "We couldn't find that roadmap"
      return nil
    end
    unless roadmap.workspace.users.exists?(current_user.id)
      redirect_to dashboard_workspaces_path, alert: "You do not have access to this workspace"
      return nil
    end
    roadmap
  end

  def sanitized_page_name(raw)
    raw.to_s.strip.sub(/\.(md|markdown)\z/i, "").strip
  end
end
