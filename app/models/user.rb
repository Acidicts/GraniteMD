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
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :workspace, optional: true

  has_one_attached :pfp_image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 400, 400 ], format: :webp, saver: { quality: 75, strip: true }
    attachable.variant :display, resize_to_limit: [ 1200, 1200 ], format: :webp, saver: { quality: 78, strip: true }
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, uniqueness: { message: "Email in Use" }
  validates :password,
            length: { minimum: 8 },
            format: {
              with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9\s]).+\z/,
              message: "must include an uppercase letter, a lowercase letter, a number, and a special character"
            },
            if: -> { password.present? }
  validates :password_confirmation, presence: true, on: :create

  attribute :first_name, null: false, default: ""
  attribute :last_name,  null: false, default: ""

  attribute :role, default: 0
  enum :role, {
    user:       0, # Standard User
    admin:      1, # Operations (Org Approval)
    superadmin: 2  # Creates Admin
  }
end
