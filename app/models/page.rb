# == Schema Information
#
# Table name: pages
#
#  id         :bigint           not null, primary key
#  body       :text
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  folder_id  :bigint           not null
#
# Indexes
#
#  index_pages_on_folder_id  (folder_id)
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => folders.id)
#
class Page < ApplicationRecord
  belongs_to :folder
  has_one :workspace, through: :folder

  validates :name, presence: true

  attribute :body, default: ""
end
