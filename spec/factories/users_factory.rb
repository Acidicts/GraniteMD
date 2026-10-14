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
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
FactoryBot.define do
  factory :user do
    # `username` and `email_address` are unique, so they have to be sequenced:
    # anything creating more than one user per example blows up otherwise.
    sequence(:email_address) { |n| "user#{n}@example.com" }
    first_name { "Test" }
    last_name { "User" }
    sequence(:username) { |n| "testuser#{n}" }
    password { "Password1!" }
    password_confirmation { "Password1!" }
  end
end
