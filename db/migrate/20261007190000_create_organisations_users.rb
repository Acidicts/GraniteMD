class CreateOrganisationsUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :organisations_users, id: false do |t|
      t.references :organisation, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true, index: false
    end

    add_index :organisations_users, [ :organisation_id, :user_id ], unique: true
  end
end
