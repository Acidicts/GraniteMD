require 'rails_helper'

# == Schema Information
#
# Table name: roadmaps
#
#  id         :bigint           not null, primary key
#  body       :text
#  header     :text
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  folder_id  :bigint           not null
#
# Indexes
#
#  index_roadmaps_on_folder_id  (folder_id)
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => folders.id)
#
RSpec.describe Roadmap, type: :model do
  describe "factory" do
    it "is valid with factory attributes" do
      expect(build(:roadmap)).to be_valid
    end

    it "persists with a folder" do
      expect { create(:roadmap) }.to change(Roadmap, :count).by(1)
    end
  end

  describe "associations" do
    it "belongs to a folder" do
      expect(Roadmap.reflect_on_association(:folder).macro).to eq(:belongs_to)
    end

    it "requires a folder" do
      roadmap = build(:roadmap, folder: nil)

      expect(roadmap).not_to be_valid
      expect(roadmap.errors[:folder]).to be_present
    end

    it "reaches its workspace through the folder" do
      roadmap = create(:roadmap)

      expect(roadmap.workspace).to eq(roadmap.folder.workspace)
      expect(roadmap.workspace).to be_present
    end

    it "is reachable through its folder" do
      folder = create(:folder)
      roadmap = create(:roadmap, folder: folder)

      expect(folder.roadmaps).to include(roadmap)
    end
  end

  describe "validations" do
    it "requires a name" do
      roadmap = build(:roadmap, name: nil)

      expect(roadmap).not_to be_valid
      expect(roadmap.errors[:name]).to be_present
    end

    it "rejects a blank name" do
      roadmap = build(:roadmap, name: "  ")

      expect(roadmap).not_to be_valid
    end
  end

  describe "categories" do
    it "orders categories by id" do
      roadmap = create(:roadmap)
      second = create(:roadmap_catagory, roadmap: roadmap, name: "Second")
      first = create(:roadmap_catagory, roadmap: roadmap, name: "First")
      # Force creation order opposite to alphabetical so ordering is by id,
      # not by name.
      expect(first.id).to be > second.id

      expect(roadmap.reload.roadmap_catagory).to eq([ second, first ])
    end

    it "destroys categories when the roadmap is destroyed" do
      roadmap = create(:roadmap)
      create(:roadmap_catagory, roadmap: roadmap)

      expect { roadmap.destroy }.to change(RoadmapCatagory, :count).by(-1)
    end
  end

  describe "tasks" do
    it "destroys tasks when the roadmap is destroyed" do
      roadmap = create(:roadmap)
      create(:roadmap_task, roadmap: roadmap, assignee: nil)

      expect { roadmap.destroy }.to change(RoadmapTask, :count).by(-1)
    end

    it "holds only its own tasks" do
      roadmap = create(:roadmap)
      other = create(:roadmap)
      task = create(:roadmap_task, roadmap: roadmap, assignee: nil)
      create(:roadmap_task, roadmap: other, assignee: nil)

      expect(roadmap.roadmap_tasks).to contain_exactly(task)
    end
  end

  describe "#get_category" do
    it "returns the category at the given index" do
      roadmap = create(:roadmap)
      first = create(:roadmap_catagory, roadmap: roadmap, name: "First")
      second = create(:roadmap_catagory, roadmap: roadmap, name: "Second")

      expect(roadmap.get_category(0)).to eq(first)
      expect(roadmap.get_category(1)).to eq(second)
    end

    it "returns nil past the end of the list" do
      roadmap = create(:roadmap)
      create(:roadmap_catagory, roadmap: roadmap)

      expect(roadmap.get_category(5)).to be_nil
    end

    it "returns nil when there are no categories" do
      expect(create(:roadmap).get_category(0)).to be_nil
    end
  end
end
