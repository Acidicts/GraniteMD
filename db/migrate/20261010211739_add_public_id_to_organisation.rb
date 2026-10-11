class AddPublicIdToOrganisation < ActiveRecord::Migration[8.1]
  def change
    add_column :organisations, :public_id, :string
    add_index :organisations, :public_id, unique: true
  end
end
