class CreateRoadmaps < ActiveRecord::Migration[8.1]
  def change
    create_table :roadmaps do |t|
      t.string :name
      t.text :body
      t.text :header

      t.timestamps
    end
  end
end
