# Plan: File upload button in workspace file explorer

**Target file:** `app/views/workspace/_file_explorer.html.erb`  
**Goal:** Let a logged-in workspace member click an "Upload file" button, pick a local file, and save it as a `WorkspaceFile` (Active Storage attachment) inside a workspace folder, then show it in the explorer tree.

## Existing foundation (reuse, don't duplicate)

- `WorkspaceFile` model: `name:string`, `folder_id: FK`, `has_one_attached :file`; `Folder#workspace_files`, `Workspace#workspace_files through folders`. Migrations exist (`create_workspace_files`, `add_folder_to_workspace_files`).
- Routes are scoped under `scope "/workspace", controller: "workspace"` and answer `turbo_stream` + `html` (e.g. `workspace_pages` → `#new_file` → `new_file.turbo_stream.erb` replaces the `workspace-file-explorer` frame).
- Stimulus controller `workspace--file-explorer` already reveals inline forms (`newPageForm`, `newFolderForm`, `newRoadmapForm`) via `data-action="click->workspace--file-explorer#showNewFileForm"` buttons; forms live in `app/views/workspace/files/forms/`.
- CSS in `app/assets/stylesheets/pages/workspace/show.css` styles `.workspace-explorer__new-file`, `.workspace-explorer__menu-btn`, etc.
- Tests in `spec/requests/workspace_explorer_spec.rb` cover the explorer with the same authorize/reject patterns.
- `WorkspaceFile` rows are not yet rendered anywhere in the tree; `_file_preview.html.erb` exists but is empty (preview is a later item).

## Out of scope for this plan

Direct-to-S3 uploads, drag-and-drop, preview/download buttons, file-type rendering (image/CSV/PDF/video), storage quota enforcement. Those are follow-ups tracked in PLAN.md under Files → File.

## Implementation steps

1. **Model validations** — `app/models/workspace_file.rb`: validate `name` presence and `File` attachment presence on create; optional content-type/size limits.
2. **Route** — `config/routes.rb`: add `post "/:workspace_public_id/files", action: :new_workspace_file, as: :workspace_files` inside the `/workspace` scope.
3. **Controller action** — `app/controllers/workspace_controller.rb`: add `#new_workspace_file` mirroring `#new_file` (resolve folder via `set_workspace` + `folder_id` param or root folder; build `WorkspaceFile`, attach `params[:workspace_file][:file]`; save; respond `turbo_stream`/`html`). Reject foreign folders and strangers using the existing `set_workspace` pattern.
4. **Turbo Stream template** — `app/views/workspace/new_workspace_file.turbo_stream.erb`: `turbo_stream.replace "workspace-file-explorer", partial: "workspace/file_explorer", locals: { workspace: @workspace }`.
5. **Form partial** — `app/views/workspace/files/forms/_new_workspace_file_form.html.erb`: `form_with url: workspace_files_path(workspace), scope: :workspace_file` with hidden `folder_id`, `file_field :file`, optional `text_field :name` (defaults to uploaded filename). `hidden` by default, target `data-workspace--file-explorer-target="newWorkspaceFileForm"`.
6. **`_file_explorer.html.erb` changes:**
   - Header: add "Upload file" button next to the `⋯` menu (only when `root_folder.present?`), `data-action="click->workspace--file-explorer#showWorkspaceFileForm" data-folder-id="<%= root_folder.id %>"`.
   - Empty states: add an upload button beside New file / New folder.
   - Render the new form partial at root and inside each folder's children (like `new_page_form`).
   - Render `workspace_file` rows in the tree: root `<ul>` and folder partial children (folders, roadmaps, pages, then workspace files).
7. **Row partial** — `app/views/workspace/files/items/_workspace_file.html.erb`: icon + name row styled like page rows, with context-menu hook for delete (later).
8. **Stimulus additions** — `app/javascript/controllers/workspace/file_explorer_controller.js`: targets `newWorkspaceFileForm`, `workspaceFileInput`; action `showWorkspaceFileForm` revealing the form for the button's folder id (mirroring `#revealNewFileForm`); guard against submitting without a file.
9. **Icon** — `app/helpers/icons_helper.rb`: add `upload_icon` (reuse `cloud_save_icon`/`file_icon` if no upload path exists).
10. **CSS** — `app/assets/stylesheets/pages/workspace/show.css`: `.workspace-explorer__upload-file` button styles plus styling for the revealed file-input row.
11. **Request spec** — `spec/requests/workspace_explorer_spec.rb`: `POST /workspace/:workspace_id/files` creates the `WorkspaceFile` with attachment, answers turbo_stream + html, rejects missing/blank file, rejects foreign folders and strangers.
12. **Model spec** — `spec/models/workspace_file_spec.rb`: attachment validation tests.
13. **PLAN.md** — mark "File upload" under Files → File as in progress/done.

## Key design decisions

- **Submit:** regular multipart form post inside the `workspace-file-explorer` Turbo frame, answered by `turbo_stream.replace "workspace-file-explorer"`. Reuses the existing pattern exactly (no Fetch/FormData needed for v1).
- **Folder scope:** button carries `data-folder-id`; controller scopes folder lookup to `workspace.folders`, so users cannot upload into other workspaces' folders — consistent with `find_authorized_folder`/`set_workspace`.
- **File name:** defaults to the uploaded filename when `name` is blank.
- **Reveal pattern:** clicking "Upload file" reveals one inline form at a time, mirroring New file/New folder for UI consistency.
