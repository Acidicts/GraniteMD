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
class RoadmapTask < ApplicationRecord
  belongs_to :roadmap
  has_one :workspace, through: :roadmap
  # Optional: an item can be created before anyone is assigned to it, and the
  # assignee can be cleared later. A deleted User nulls the column through
  # dependent: :destroy on their side.
  belongs_to :assignee, class_name: "User", inverse_of: false, optional: true

  # The column is named `category` rather than `roadmap_catagory_id`, so the
  # reference has to be spelled out. Optional because the column is nullable --
  # a task can be created before it has been filed under a column.
  belongs_to :catagory,
             class_name: "RoadmapCatagory",
             foreign_key: :category,
             optional: true,
             inverse_of: :roadmap_tasks

  validates :header, presence: true

  def get_category
    self.catagory
  end
end
