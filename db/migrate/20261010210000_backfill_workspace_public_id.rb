class BackfillWorkspacePublicId < ActiveRecord::Migration[8.1]
  def up
    Workspace.where(public_id: [ nil, "" ]).find_each do |workspace|
      workspace.send(:ensure_public_id)
      workspace.update_column(:public_id, workspace.public_id)
    end
  end

  def down
    # No-op: keep assigned public ids.
  end
end
