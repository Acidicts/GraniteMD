require 'rails_helper'

RSpec.describe "Workspace headings nav", type: :request do
  let!(:user) { create(:user) }

  before { sign_in user }

  it "renders the headings toggle and overlay panel in the editor" do
    workspace = Workspace.create!(name: "Nav", feature_set: "personal")
    workspace.users << user
    folder = Folder.create!(name: "Docs", workspace: workspace)
    page = Page.create!(name: "guide", body: "# Hello\n\n## Setup\n", folder: folder)

    get workspace_page_path(workspace, page)

    expect(response).to be_successful
    expect(response.body).to include("toc-toggle")
    expect(response.body).to include('data-action="click->markdown#toggleToc"')
    expect(response.body).to include('data-markdown-target="arc"')
    expect(response.body).to include("wheel->markdown#onWheelSpin")
    expect(response.body).to include("pointerdown->markdown#onWheelGrab")
  end
end
