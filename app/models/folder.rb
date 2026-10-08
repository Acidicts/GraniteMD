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
class Folder < ApplicationRecord
  belongs_to :workspace
  belongs_to :parent, class_name: "Folder", optional: true, inverse_of: :folders
  has_many :folders, class_name: "Folder", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :pages, dependent: :destroy

  before_validation :inherit_workspace_from_parent

  private

  def inherit_workspace_from_parent
    self.workspace ||= parent&.workspace
  end
end
