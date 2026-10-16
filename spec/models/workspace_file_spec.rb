require 'rails_helper'

# == Schema Information
#
# Table name: workspace_files
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  folder_id  :bigint           not null
#
# Indexes
#
#  index_workspace_files_on_folder_id  (folder_id)
#
RSpec.describe WorkspaceFile, type: :model do
  describe "factory" do
    it "is valid with factory attributes" do
      expect(build(:workspace_file)).to be_valid
    end

    it "persists with a folder" do
      expect { create(:workspace_file) }.to change(WorkspaceFile, :count).by(1)
    end
  end

  describe "validations" do
    it "requires a name" do
      file = build(:workspace_file, name: nil)

      expect(file).not_to be_valid
      expect(file.errors[:name]).to be_present
    end

    it "does not save without a name" do
      file = build(:workspace_file, name: "")

      expect(file.save).to be(false)
      expect(file.persisted?).to be(false)
    end
  end

  describe "associations" do
    it "belongs to a folder" do
      expect(WorkspaceFile.reflect_on_association(:folder).macro).to eq(:belongs_to)
    end

    it "requires a folder" do
      file = build(:workspace_file, folder: nil)

      expect(file).not_to be_valid
      expect(file.errors[:folder]).to be_present
    end

    it "reaches its workspace through the folder" do
      expect(WorkspaceFile.reflect_on_association(:workspace).macro).to eq(:has_one)
      expect(WorkspaceFile.reflect_on_association(:workspace).options[:through]).to eq(:folder)
    end

    it "returns the folder's workspace" do
      file = create(:workspace_file)

      expect(file.workspace).to eq(file.folder.workspace)
    end
  end
end
