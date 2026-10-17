class RenameWorkspaceFileAttachmentToLowercase < ActiveRecord::Migration[8.1]
  def up
    ActiveStorage::Attachment.where(record_type: "WorkspaceFile", name: "File")
                             .update_all(name: "file")
  end

  def down
    ActiveStorage::Attachment.where(record_type: "WorkspaceFile", name: "file")
                             .update_all(name: "File")
  end
end
