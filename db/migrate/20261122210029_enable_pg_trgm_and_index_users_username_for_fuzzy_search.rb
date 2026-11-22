class EnablePgTrgmAndIndexUsersUsernameForFuzzySearch < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_trgm"

    add_index :users, :username,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_users_on_username_trgm"
  end

  def down
    remove_index :users, name: "index_users_on_username_trgm", if_exists: true
  end
end
