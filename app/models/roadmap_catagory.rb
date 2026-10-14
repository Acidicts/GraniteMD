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
class RoadmapCatagory < ApplicationRecord
  belongs_to :roadmap

  # `roadmap_tasks.category` points at `roadmap_catagories.id` but the column is
  # a bare integer, so the join has to be spelled out instead of inferred. The
  # extra roadmap_id match stops tasks from leaking across roadmaps when a
  # category id is reused.
  has_many :roadmap_tasks,
           ->(catagory) { where(roadmap_id: catagory.roadmap_id) },
           foreign_key: :category,
           primary_key: :id,
           inverse_of: :catagory

  validates :name, presence: true
  validates :name, uniqueness: { scope: :roadmap_id, message: "Category Already Exists" }
end
