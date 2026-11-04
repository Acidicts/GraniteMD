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
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
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

    it "orphans assigned roadmap tasks instead of deleting them" do
      user = create(:user)
      task = create(:roadmap_task, assignee: user)

      expect { user.destroy }.not_to change(RoadmapTask, :count)
      expect(task.reload.assignee).to be_nil
    end

    it "belongs to many workspaces" do
      user = create(:user)
      workspace = create(:workspace)

      user.workspaces << workspace

      expect(user.workspaces).to include(workspace)
      expect(workspace.users).to include(user)
    end

    it "drops memberships when destroyed" do
      user = create(:user)
      workspace = create(:workspace)
      user.workspaces << workspace

      expect { user.destroy }.to change { workspace.users.reload.count }.by(-1)
    end
  end

  describe "greet email" do
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("APP_HOST").and_return("https://example.com")
    end

    it "enqueues the welcome email when greet_email is true" do
      expect {
        create(:user, email_address: "sam@example.com", greet_email: true)
      }.to have_enqueued_mail(EmailMailer, :send_email).with(
        a_hash_including(
          to: "sam@example.com",
          subject: "Welcome to GraniteMD"
        )
      )
    end

    it "links to the dashboard with a well-formed URL" do
      expect {
        create(:user, greet_email: true)
      }.to have_enqueued_mail(EmailMailer, :send_email).with(
        a_hash_including(body: a_string_including('<a href="https://example.com/dashboard">here</a>'))
      )
    end

    it "does not send when greet_email is omitted" do
      expect { create(:user) }.not_to have_enqueued_mail(EmailMailer, :send_email)
    end

    it "does not send when greet_email is false" do
      expect {
        create(:user, greet_email: false)
      }.not_to have_enqueued_mail(EmailMailer, :send_email)
    end

    it "treats the string 'false' as false (e.g. from params)" do
      expect {
        create(:user, greet_email: "false")
      }.not_to have_enqueued_mail(EmailMailer, :send_email)
    end

    it "does not send on update" do
      user = create(:user, greet_email: true)
      clear_enqueued_jobs

      expect {
        user.update!(first_name: "Sam")
      }.not_to have_enqueued_mail(EmailMailer, :send_email)
    end

    it "does not send if the record fails to save" do
      user = build(:user, password: "short", password_confirmation: "short", greet_email: true)

      expect { user.save }.not_to have_enqueued_mail(EmailMailer, :send_email)
      expect(user).not_to be_persisted
    end

    it "does not persist the flag" do
      user = create(:user, greet_email: true)

      expect(User.find(user.id).greet_email).to be(false)
    end
  end
end
