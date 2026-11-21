class AddAppealLockedToOrganisationApplication < ActiveRecord::Migration[8.1]
  def change
    add_column :organisation_applications, :appeal_locked, :boolean, default: false, null: false
  end
end
