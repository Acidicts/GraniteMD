class CreateUsersWorkspaces < ActiveRecord::Migration[8.1]
  def change
    create_table :users_workspaces, id: false do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :workspace, null: false, foreign_key: true, index: false
    end

    add_index :users_workspaces, [ :user_id, :workspace_id ], unique: true

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO users_workspaces (user_id, workspace_id)
          SELECT id, workspace_id FROM users WHERE workspace_id IS NOT NULL
          ON CONFLICT DO NOTHING
        SQL
      end
    end
  end
end
