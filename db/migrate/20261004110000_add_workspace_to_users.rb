class AddWorkspaceToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :workspace, null: true, foreign_key: true
  end
end
