require 'rails_helper'

RSpec.describe "workspace/files/items/_roadmap_task" do
  let!(:user) { create(:user) }
  let!(:workspace) do
    Workspace.create!(name: "Roadmaps", feature_set: "personal").tap { |ws| ws.users << user }
  end
  let!(:roadmap) { Roadmap.create!(name: "Launch", folder: Folder.create!(name: "Product", workspace: workspace)) }
  let!(:task) { RoadmapTask.create!(roadmap: roadmap, header: "ship it", assignee: user) }

  def render_card(roadmap_task)
    ApplicationController.render(partial: "workspace/files/items/roadmap_task",
                                 locals: { roadmap_task: roadmap_task })
  end

  it "renders the organisation name" do
    workspace.update!(organisation: Organisation.create!(name: "Acme"))

    expect(render_card(task)).to include("Acme")
  end

  it "falls back to the workspace name when there is no organisation" do
    expect(render_card(task)).to include("Roadmaps")
  end

  # A personal workspace has no organisation, so the chain must survive one
  # being nil.
  it "renders when the workspace has no organisation" do
    expect(workspace.organisation).to be_nil

    expect(render_card(task)).to include("ship it")
  end

  # assignee_id is nullable now that the migration landed.
  it "renders when the task has no assignee" do
    task.update!(assignee: nil)

    expect(render_card(task.reload)).to include("ship it")
  end

  # roadmap -> folder -> workspace is a chain of required belongs_to on NOT NULL
  # columns, so it always resolves for a saved row -- but an unsaved task has no
  # roadmap, and walking `.roadmap.workspace` unguarded used to raise here.
  it "renders an unsaved task that has no roadmap yet" do
    expect { render_card(RoadmapTask.new(header: "draft", assignee: user)) }.not_to raise_error
  end

  it "links to the edit page only when the task can be reached" do
    expect(render_card(task)).to include(edit_workspace_roadmap_item_path(workspace, roadmap, task))

    unsaved = render_card(RoadmapTask.new(header: "draft", assignee: user))

    expect(unsaved).to include("draft")
    expect(unsaved).not_to include("Edit item")
    expect(unsaved).not_to include("/items/")
  end

  it "renders an unsaved task filed under a roadmap without an edit link" do
    unsaved = render_card(RoadmapTask.new(header: "draft", assignee: nil, roadmap: roadmap))

    expect(unsaved).to include("draft")
    expect(unsaved).to include("Unassigned")
    expect(unsaved).not_to include("Edit item")
  end
end
