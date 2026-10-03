# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email_address   :string           not null
#  name            :string
#  password_digest :string           not null
#  role            :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_one_attached :pfp_image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 400, 400 ], format: :webp, saver: { quality: 75, strip: true }
    attachable.variant :display, resize_to_limit: [ 1200, 1200 ], format: :webp, saver: { quality: 78, strip: true }
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  attribute :name, null: false, default: ""

  attribute :role, default: 0
  enum :role, {
    user:       0, # Standard User
    admin:      1, # Operations (Org Approval)
    superadmin: 2  # Creates Admin
  }
end
