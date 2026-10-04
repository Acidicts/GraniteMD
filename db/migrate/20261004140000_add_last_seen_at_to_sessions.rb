class AddLastSeenAtToSessions < ActiveRecord::Migration[8.1]
  def up
    add_column :sessions, :last_seen_at, :datetime
    execute "UPDATE sessions SET last_seen_at = created_at WHERE last_seen_at IS NULL"
    change_column_null :sessions, :last_seen_at, false
  end

  def down
    remove_column :sessions, :last_seen_at
  end
end
