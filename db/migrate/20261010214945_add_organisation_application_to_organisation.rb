class AddOrganisationApplicationToOrganisation < ActiveRecord::Migration[8.1]
  def change
    add_reference :organisations, :organisation_application, null: true, foreign_key: true
  end
end
