class AddOrganisationLockedToUser < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :organisation_locked, null: true, foreign_key: { to_table: :organisations }
  end
end
