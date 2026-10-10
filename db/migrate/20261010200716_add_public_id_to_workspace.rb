class AddPublicIdToWorkspace < ActiveRecord::Migration[8.1]
  def change
    add_column :workspaces, :public_id, :string
  end
end
