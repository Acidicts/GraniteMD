class CreateRoadmapCatagories < ActiveRecord::Migration[8.1]
  def change
    create_table :roadmap_catagories do |t|
      t.string :name
      t.references :roadmap, null: false, foreign_key: true

      t.timestamps
    end
  end
end
