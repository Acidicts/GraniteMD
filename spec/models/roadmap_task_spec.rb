require 'rails_helper'

# == Schema Information
#
# Table name: roadmap_tasks
#
#  id          :bigint           not null, primary key
#  body        :text
#  category    :integer
#  header      :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  assignee_id :bigint
#  roadmap_id  :bigint           not null
#
# Indexes
#
#  index_roadmap_tasks_on_assignee_id  (assignee_id)
#  index_roadmap_tasks_on_roadmap_id   (roadmap_id)
#
# Foreign Keys
#
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (roadmap_id => roadmaps.id)
#
RSpec.describe RoadmapTask, type: :model do
  let(:roadmap) { create(:roadmap) }

  describe "assignee" do
    it "is optional" do
      task = build(:roadmap_task, roadmap: roadmap, assignee: nil)

      expect(task).to be_valid
      expect { create(:roadmap_task, roadmap: roadmap, assignee: nil) }
        .to change(RoadmapTask, :count).by(1)
    end

    it "still records one when given" do
      user = create(:user)

      task = create(:roadmap_task, roadmap: roadmap, assignee: user)

      expect(task.reload.assignee).to eq(user)
    end

    it "can be cleared after the fact" do
      task = create(:roadmap_task, roadmap: roadmap, assignee: create(:user))

      expect(task.update(assignee: nil)).to be true
      expect(task.reload.assignee).to be_nil
    end

    it "is reached from the user" do
      user = create(:user)
      task = create(:roadmap_task, roadmap: roadmap, assignee: user)

      expect(user.roadmap_tasks).to contain_exactly(task)
    end
  end

  describe "validations" do
    it "requires a header" do
      task = build(:roadmap_task, roadmap: roadmap, header: nil)

      expect(task).not_to be_valid
      expect(task.errors[:header]).to be_present
    end

    it "requires a roadmap" do
      task = build(:roadmap_task, roadmap: nil, assignee: nil)

      expect(task).not_to be_valid
      expect(task.errors[:roadmap]).to be_present
    end
  end

  describe "#get_category" do
    it "returns the catagory it references" do
      done = create(:roadmap_catagory, roadmap: roadmap, name: "Done")
      task = create(:roadmap_task, roadmap: roadmap, category: done.id, assignee: nil)

      expect(task.get_category).to eq(done)
    end

    it "returns nil when it has no catagory" do
      task = create(:roadmap_task, roadmap: roadmap, category: nil, assignee: nil)

      expect(task.get_category).to be_nil
    end
  end
end
