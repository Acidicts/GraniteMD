class CreateOrganisationApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :organisation_applications do |t|
      t.integer :status
      t.string :name
      t.integer :owner_id

      t.timestamps
    end
  end
end
