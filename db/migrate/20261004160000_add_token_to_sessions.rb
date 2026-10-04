class AddTokenToSessions < ActiveRecord::Migration[8.1]
  def up
    add_column :sessions, :token, :string
    backfill_tokens
    change_column_null :sessions, :token, false
    add_index :sessions, :token, unique: true
  end

  def down
    remove_index :sessions, :token
    remove_column :sessions, :token
  end

  private
  # Same generator as has_secure_token so backfilled and new rows are
  # indistinguishable. Done in Ruby rather than SQL to avoid depending on the
  # pgcrypto extension being installed.
  def backfill_tokens
    Session.reset_column_information
    Session.where(token: nil).find_each do |record|
      token = Session.generate_unique_secure_token
      token = Session.generate_unique_secure_token while Session.exists?(token: token)
      record.update_column(:token, token)
    end
  end
end
