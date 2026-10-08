require 'rails_helper'

# == Schema Information
#
# Table name: folders
#
#  id           :bigint           not null, primary key
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  parent_id    :bigint
#  workspace_id :bigint           not null
#
# Indexes
#
#  index_folders_on_parent_id     (parent_id)
#  index_folders_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => folders.id)
#  fk_rails_...  (workspace_id => workspaces.id)
#
RSpec.describe Folder, type: :model do
  describe "factory" do
    it "is valid with factory attributes" do
      expect(build(:folder)).to be_valid
    end

    it "persists with a workspace" do
      expect { create(:folder) }.to change(Folder, :count).by(1)
    end
  end

  describe "associations" do
    it "belongs to a workspace" do
      expect(Folder.reflect_on_association(:workspace).macro).to eq(:belongs_to)
    end

    it "requires a workspace without a parent" do
      folder = build(:folder, workspace: nil)

      expect(folder).not_to be_valid
      expect(folder.errors[:workspace]).to be_present
    end

    it "optionally belongs to a parent folder" do
      association = Folder.reflect_on_association(:parent)

      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to be(true)
    end

    it "is valid without a parent" do
      expect(build(:folder, parent: nil)).to be_valid
    end

    it "has many child folders" do
      parent = create(:folder)
      child = create(:folder, parent: parent, workspace: parent.workspace)

      expect(parent.folders).to include(child)
      expect(child.parent).to eq(parent)
      expect(Folder.reflect_on_association(:folders).macro).to eq(:has_many)
    end

    it "has many pages" do
      folder = create(:folder)
      page = create(:page, folder: folder)

      expect(folder.pages).to include(page)
      expect(Folder.reflect_on_association(:pages).macro).to eq(:has_many)
    end
  end

  describe "workspace inheritance from parent" do
    it "inherits the workspace from its parent when none is given" do
      parent = create(:folder)
      child = build(:folder, parent: parent, workspace: nil)

      expect(child.valid?).to be(true)
      expect(child.workspace).to eq(parent.workspace)
    end

    it "keeps an explicitly assigned workspace instead of the parent's" do
      parent = create(:folder)
      other_workspace = create(:workspace)
      child = build(:folder, parent: parent, workspace: other_workspace)

      child.valid?

      expect(child.workspace).to eq(other_workspace)
    end

    it "remains invalid without a workspace or a parent workspace" do
      orphan_parent = build(:folder, workspace: nil)
      child = build(:folder, parent: orphan_parent, workspace: nil)

      expect(child).not_to be_valid
      expect(child.errors[:workspace]).to be_present
    end
  end

  describe "dependent destroy" do
    it "destroys child folders when the parent is destroyed" do
      parent = create(:folder)
      create(:folder, parent: parent, workspace: parent.workspace)

      expect { parent.destroy }.to change(Folder, :count).by(-2)
    end

    it "destroys pages when the folder is destroyed" do
      folder = create(:folder)
      create(:page, folder: folder)

      expect { folder.destroy }.to change(Page, :count).by(-1)
    end
  end
end
