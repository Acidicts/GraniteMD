class AddOwnerToOrganisation < ActiveRecord::Migration[8.1]
  def up
    add_column :organisations, :owner_id, :bigint

    execute <<~SQL
      UPDATE organisations
      SET owner_id = organisation_applications.owner_id
      FROM organisation_applications
      WHERE organisations.organisation_application_id = organisation_applications.id
        AND organisations.owner_id IS NULL
        AND organisation_applications.owner_id IS NOT NULL
    SQL
  end

  def down
    remove_column :organisations, :owner_id
  end
end
