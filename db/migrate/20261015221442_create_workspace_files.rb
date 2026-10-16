class CreateWorkspaceFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :workspace_files do |t|
      t.string :name

      t.timestamps
    end
  end
end
