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
class User < ApplicationRecord
  PASSWORD_RESET_TOKEN_TTL = 15.minutes
  DEFAULT_STORAGE = 50.megabytes

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_and_belongs_to_many :workspaces
  has_and_belongs_to_many :organisations

  generates_token_for :password_reset, expires_in: PASSWORD_RESET_TOKEN_TTL do
    password_digest
  end

  has_one_attached :pfp_image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 400, 400 ], format: :webp, saver: { quality: 75, strip: true }
    attachable.variant :display, resize_to_limit: [ 1200, 1200 ], format: :webp, saver: { quality: 78, strip: true }
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :username, with: ->(u) { u.strip.downcase }
  validates :username, uniqueness: { case_sensitive: false, message: "Username in Use" }
  validates :email_address, uniqueness: { message: "Email in Use" }
  validates :password,
            length: { minimum: 8 },
            format: {
              with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9\s]).+\z/,
              message: "must include an uppercase letter, a lowercase letter, a number, and a special character"
            },
            if: -> { password.present? }
  validates :password_confirmation, presence: true, if: -> { password.present? }

  encrypts :first_name
  encrypts :last_name

  encrypts :email_address, deterministic: true
  validate :pfp_image_content_type
  validate :pfp_image_size


  attribute :first_name, null: false, default: ""
  attribute :last_name,  null: false, default: ""

  attribute :role, default: 0
  enum :role, {
    user:       0, # Standard User
    admin:      1, # Operations (Org Approval)
    superadmin: 2  # Creates Admin
  }

  def available_storage
    DEFAULT_STORAGE - self.used_storage.to_i.bytes
  end

  def used_storage
    self.workspaces.sum(&:get_storage_use)
  end

  def pfp_image_content_type
    return unless pfp_image.attached?

    type = pfp_image.blob.content_type.to_s
    if ![ "image/jpeg", "image/png", "image/gif", "image/webp" ].include?(type)
      errors.add(:base, "must be an image (jpg, png, gif, webp)")
    end
  end

  def pfp_image_size
    return unless pfp_image.attached?

    if pfp_image.byte_size >= 2.megabytes
      errors.add(:base, "must be less than 2MB")
    end
  end
end
