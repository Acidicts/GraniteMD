class CreatePages < ActiveRecord::Migration[8.1]
  def change
    create_table :pages do |t|
      t.text :body
      t.string :name
      t.references :folder, null: false, foreign_key: true

      t.timestamps
    end
  end
end
