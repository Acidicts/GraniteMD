require 'rails_helper'

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
RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:user)).to be_valid
    end

    it "requires a unique email address" do
      create(:user, email_address: "taken@example.com")
      duplicate = build(:user, email_address: "taken@example.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email_address]).to include("Email in Use")
    end

    it "normalizes the email address" do
      user = create(:user, email_address: "  Mixed.Case@Example.COM ")
      expect(user.email_address).to eq("mixed.case@example.com")
    end

    it "requires a password of at least 8 characters" do
      user = build(:user, password: "Ab1!xyz", password_confirmation: "Ab1!xyz")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "requires the password to include upper, lower, number and special character" do
      user = build(:user, password: "alllowercase1", password_confirmation: "alllowercase1")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end

    it "requires a password confirmation when created" do
      user = build(:user, password_confirmation: nil)

      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to be_present
    end

    it "validates the password only when it changes" do
      user = create(:user)
      user.last_name = "Updated"

      expect(user).to be_valid
    end
  end

  describe "roles" do
    it "defaults to the user role" do
      expect(build(:user).role).to eq("user")
    end

    it "supports admin and superadmin roles" do
      expect(build(:user, role: :admin)).to be_admin
      expect(build(:user, role: :superadmin)).to be_superadmin
    end
  end

  describe "associations" do
    it "has many sessions" do
      user = create(:user)
      user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")

      expect(user.sessions.count).to eq(1)
    end

    it "destroys dependent sessions" do
      user = create(:user)
      user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")

      expect { user.destroy }.to change(Session, :count).by(-1)
    end
  end
end
