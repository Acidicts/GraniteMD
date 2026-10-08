require 'rails_helper'

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
RSpec.describe Folder, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
