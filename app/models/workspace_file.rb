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
class WorkspaceFile < ApplicationRecord
  belongs_to :folder
  has_one :workspace, through: :folder

  has_one_attached :file

  validates :name, presence: true
end
