class AddOwnerIdToWorkspace < ActiveRecord::Migration[8.1]
  def change
    add_column :workspaces, :owner_id, :integer
  end
end
