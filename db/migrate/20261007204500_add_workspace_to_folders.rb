class AddWorkspaceToFolders < ActiveRecord::Migration[8.1]
  def change
    add_reference :folders, :workspace, null: false, foreign_key: true
  end
end
