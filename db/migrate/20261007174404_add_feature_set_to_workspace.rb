class AddFeatureSetToWorkspace < ActiveRecord::Migration[8.1]
  def change
    add_column :workspaces, :feature_set, :integer
  end
end
