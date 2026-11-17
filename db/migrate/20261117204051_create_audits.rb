class CreateAudits < ActiveRecord::Migration[8.1]
  def change
    create_table :audits do |t|
      t.string :action, null: false
      t.json :details

      t.references :user, null: true, foreign_key: true

      t.references :auditable, polymorphic: true, null: true

      t.timestamps
    end

    add_index :audits, :action
  end
end
