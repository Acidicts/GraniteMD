# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email_address   :string           not null
#  first_name      :string
#  last_name       :string
#  password_digest :string           not null
#  role            :integer
#  username        :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  workspace_id    :bigint
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#  index_users_on_workspace_id   (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => workspaces.id)
#
FactoryBot.define do
  factory :user do
    email_address { "user@example.com" }
    first_name { "Test" }
    last_name { "User" }
    username { "testuser" }
    password { "Password1!" }
    password_confirmation { "Password1!" }
  end
end
