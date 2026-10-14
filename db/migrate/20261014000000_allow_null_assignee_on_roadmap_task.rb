class AllowNullAssigneeOnRoadmapTask < ActiveRecord::Migration[8.1]
  def change
    # Items can be created before anyone is assigned to them, and a task whose
    # assignee is removed should survive. The foreign key stays; a NULL column
    # just has no row to point at.
    change_column_null :roadmap_tasks, :assignee_id, true
  end
end
