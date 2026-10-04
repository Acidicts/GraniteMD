require 'rails_helper'

# == Schema Information
#
# Table name: workspaces
#
#  id         :bigint           not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
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
    it { is_expected.to have_many(:users) }
  end
end
