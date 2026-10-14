class CreateRoadmapTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :roadmap_tasks do |t|
      t.string :header
      t.text :body
      t.integer :category
      t.references :roadmap, null: false, foreign_key: true

      t.timestamps
    end
  end
end
