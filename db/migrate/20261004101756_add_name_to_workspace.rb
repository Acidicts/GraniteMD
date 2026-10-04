class AddNameToWorkspace < ActiveRecord::Migration[8.1]
  def change
    add_column :workspaces, :name, :string, null: false, default: ""
  end
end
