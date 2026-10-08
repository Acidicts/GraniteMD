require 'rails_helper'

# == Schema Information
#
# Table name: organisations
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
RSpec.describe Organisation, type: :model do
  describe "factory" do
    it "is valid with factory attributes" do
      expect(build(:organisation)).to be_valid
    end

    it "persists" do
      expect { create(:organisation) }.to change(Organisation, :count).by(1)
    end
  end

  describe "attributes" do
    it "is valid without a name (no presence validation)" do
      expect(build(:organisation, name: nil)).to be_valid
    end
  end

  describe "associations" do
    it "has and belongs to many users" do
      expect(Organisation.reflect_on_association(:users).macro).to eq(:has_and_belongs_to_many)
    end

    it "has many workspaces" do
      expect(Organisation.reflect_on_association(:workspaces).macro).to eq(:has_many)
    end

    it "can have users added" do
      organisation = create(:organisation)
      user = create(:user, email_address: "org-member@example.com", username: "orgmember")

      organisation.users << user

      expect(organisation.users).to contain_exactly(user)
      expect(user.organisations).to include(organisation)
    end

    it "can have multiple users" do
      organisation = create(:organisation)
      first = create(:user, email_address: "org-first@example.com", username: "orgfirst")
      second = create(:user, email_address: "org-second@example.com", username: "orgsecond")

      organisation.users << [ first, second ]

      expect(organisation.users).to contain_exactly(first, second)
    end

    it "can have workspaces added" do
      organisation = create(:organisation)
      workspace = create(:workspace, organisation: organisation)

      expect(organisation.workspaces).to include(workspace)
      expect(workspace.organisation).to eq(organisation)
    end
  end
end
