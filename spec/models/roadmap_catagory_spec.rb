require 'rails_helper'

# == Schema Information
#
# Table name: roadmap_catagories
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  roadmap_id :bigint           not null
#
# Indexes
#
#  index_roadmap_catagories_on_roadmap_id  (roadmap_id)
#
# Foreign Keys
#
#  fk_rails_...  (roadmap_id => roadmaps.id)
#
RSpec.describe RoadmapCatagory, type: :model do
  describe "factory" do
    it "is valid with factory attributes" do
      expect(build(:roadmap_catagory)).to be_valid
    end

    it "persists with a roadmap" do
      expect { create(:roadmap_catagory) }.to change(RoadmapCatagory, :count).by(1)
    end
  end

  describe "associations" do
    it "belongs to a roadmap" do
      expect(RoadmapCatagory.reflect_on_association(:roadmap).macro).to eq(:belongs_to)
    end

    it "requires a roadmap" do
      catagory = build(:roadmap_catagory, roadmap: nil)

      expect(catagory).not_to be_valid
      expect(catagory.errors[:roadmap]).to be_present
    end

    it "is reachable through its roadmap" do
      roadmap = create(:roadmap)
      catagory = create(:roadmap_catagory, roadmap: roadmap)

      expect(roadmap.roadmap_catagory).to include(catagory)
      expect(catagory.roadmap).to eq(roadmap)
    end
  end

  describe "roadmap_tasks" do
    let(:roadmap) { create(:roadmap) }
    let(:user) { create(:user) }
    let(:done) { create(:roadmap_catagory, roadmap: roadmap, name: "Done") }
    let!(:doing) { create(:roadmap_catagory, roadmap: roadmap, name: "Doing") }

    it "holds the tasks that reference it" do
      task = create(:roadmap_task, roadmap: roadmap, category: done.id, assignee: user)

      expect(done.roadmap_tasks).to contain_exactly(task)
      expect(doing.roadmap_tasks).to be_empty
    end

    it "is the inverse of RoadmapTask#catagory" do
      task = create(:roadmap_task, roadmap: roadmap, category: doing.id, assignee: user)

      expect(task.catagory).to eq(doing)
      expect(task.get_category).to eq(doing)
      expect(doing.roadmap_tasks).to contain_exactly(task)
    end

    # The column is a bare integer, so an id reused on another roadmap would
    # otherwise pull in tasks that belong elsewhere.
    it "does not pick up tasks from another roadmap" do
      other = create(:roadmap)
      create(:roadmap_catagory, roadmap: other, name: "Foreign")
      create(:roadmap_task, roadmap: other, category: done.id, assignee: user)

      expect(done.roadmap_tasks).to be_empty
    end

    it "leaves a task with no catagory out of every list" do
      create(:roadmap_task, roadmap: roadmap, category: nil, assignee: user)

      expect(done.roadmap_tasks).to be_empty
      expect(doing.roadmap_tasks).to be_empty
    end
  end

  describe "validations" do
    it "requires a name" do
      catagory = build(:roadmap_catagory, name: nil)

      expect(catagory).not_to be_valid
      expect(catagory.errors[:name]).to be_present
    end

    it "rejects a duplicate name in the same roadmap" do
      roadmap = create(:roadmap)
      create(:roadmap_catagory, roadmap: roadmap, name: "Done")
      duplicate = build(:roadmap_catagory, roadmap: roadmap, name: "Done")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("Category Already Exists")
    end

    it "allows the same name in a different roadmap" do
      create(:roadmap_catagory, roadmap: create(:roadmap), name: "Done")
      other = build(:roadmap_catagory, roadmap: create(:roadmap), name: "Done")

      expect(other).to be_valid
    end

    it "allows a different name in the same roadmap" do
      roadmap = create(:roadmap)
      create(:roadmap_catagory, roadmap: roadmap, name: "Done")

      expect(build(:roadmap_catagory, roadmap: roadmap, name: "In Progress")).to be_valid
    end

    it "allows the same name for an unsaved record" do
      expect(build(:roadmap_catagory, name: "Done")).to be_valid
    end
  end
end
