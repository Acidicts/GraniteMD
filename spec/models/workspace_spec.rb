require 'rails_helper'

# == Schema Information
#
# Table name: workspaces
#
#  id              :bigint           not null, primary key
#  feature_set     :integer
#  name            :string           default(""), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organisation_id :bigint
#  owner_id        :integer
#  public_id       :string
#
# Indexes
#
#  index_workspaces_on_organisation_id  (organisation_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#
RSpec.describe Workspace, type: :model do
  describe "validations" do
    it "is valid with a name" do
      expect(build(:workspace)).to be_valid
    end

    it "requires a name" do
      workspace = build(:workspace, name: "")

      expect(workspace).not_to be_valid
      expect(workspace.errors[:name]).to be_present
    end

    it "does not save without a name" do
      workspace = build(:workspace, name: nil)

      expect(workspace.save).to be(false)
      expect(workspace.persisted?).to be(false)
    end
  end

  describe "defaults" do
    it "starts with an empty name" do
      expect(Workspace.new.name).to eq("")
    end
  end

  describe "associations" do
    it "shares users through the membership join table" do
      workspace = create(:workspace)
      user = create(:user)

      workspace.users << user

      expect(workspace.users).to contain_exactly(user)
      expect(Workspace.reflect_on_association(:users).macro).to eq(:has_and_belongs_to_many)
    end
  end
end
