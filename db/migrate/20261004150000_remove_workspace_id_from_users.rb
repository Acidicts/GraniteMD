class RemoveWorkspaceIdFromUsers < ActiveRecord::Migration[8.1]
  def up
    remove_reference :users, :workspace, foreign_key: true, index: true
  end

  def down
    add_reference :users, :workspace, null: true, foreign_key: true
  end
end
