require "rails_helper"

RSpec.describe "Workspace file preview", type: :request do
  let!(:user) { create(:user) }
  before { sign_in user }

  def workspace_with_member(name: "Preview")
    Workspace.create!(name: name, feature_set: "personal").tap { |ws| ws.users << user }
  end

  def upload_csv(folder, name: "data.csv", content: "a,b\n1,2\n")
    create(:workspace_file, name: name, folder: folder).tap do |file|
      file.file.attach(io: StringIO.new(content), filename: name, content_type: "text/csv")
    end
  end

  it "renders a CSV preview table" do
    workspace = workspace_with_member
    file = upload_csv(workspace.ensure_root_folder)

    get workspace_file_path(workspace, file)

    expect(response).to be_successful
    expect(response.body).to include("workspace-editor")
    expect(response.body).to include("file-preview__table")
    expect(response.body).to include("<th scope=\"col\">a</th>")
    expect(response.body).to include("<td>1</td>")
  end

  it "shows a fallback for malformed CSV instead of raising" do
    workspace = workspace_with_member
    file = upload_csv(workspace.ensure_root_folder, content: "a,b\n\"unclosed,quote\n")

    get workspace_file_path(workspace, file)

    expect(response).to be_successful
    expect(response.body).to include("Couldn't preview this CSV file")
  end

  it "rejects other workspaces' files and strangers" do
    workspace = workspace_with_member
    file = upload_csv(workspace.ensure_root_folder)

    other = Workspace.create!(name: "Other", feature_set: "personal")
    get workspace_file_path(other, file)
    expect(response).to redirect_to(dashboard_workspaces_path)

    stranger = create(:user, username: "preview_stranger", email_address: "preview_stranger@example.com")
    delete logout_path
    sign_in stranger
    get workspace_file_path(workspace, file)
    expect(response).to redirect_to(dashboard_workspaces_path)
  end
end
