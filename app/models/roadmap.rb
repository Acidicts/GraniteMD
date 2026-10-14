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
class Roadmap < ApplicationRecord
  belongs_to :folder
  has_one :workspace, through: :folder

  # Ordered explicitly: `get_category` and the drag/drop move endpoint both
  # address categories by position in this list, so the order has to be pinned
  # down rather than left to whatever the database happens to return.
  has_many :roadmap_catagory, -> { order(:id) }, dependent: :destroy
  has_many :roadmap_tasks, dependent: :destroy

  validates :name, presence: true

  # Position in the ordered category list, or nil if the index is past the end.
  # `[]` rather than `find`: `find(0)` is a primary-key lookup and would always
  # come back nil, which is what this used to do.
  def get_category(index)
    self.roadmap_catagory[index]
  end
end
