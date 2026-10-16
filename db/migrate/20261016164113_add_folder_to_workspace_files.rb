class AddFolderToWorkspaceFiles < ActiveRecord::Migration[8.1]
  def change
    add_reference :workspace_files, :folder, null: false, index: true
  end
end
