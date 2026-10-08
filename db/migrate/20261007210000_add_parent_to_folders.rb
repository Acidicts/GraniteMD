class AddParentToFolders < ActiveRecord::Migration[8.1]
  def change
    add_reference :folders, :parent, foreign_key: { to_table: :folders }
  end
end
