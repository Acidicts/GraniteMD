class AddAssigneeToRoadmapTask < ActiveRecord::Migration[8.1]
  def change
    add_reference :roadmap_tasks, :assignee, null: false, foreign_key: { to_table: :users }
  end
end
