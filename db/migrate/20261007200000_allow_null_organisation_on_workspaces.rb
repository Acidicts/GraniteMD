class AllowNullOrganisationOnWorkspaces < ActiveRecord::Migration[8.1]
  def change
    change_column_null :workspaces, :organisation_id, true
  end
end
