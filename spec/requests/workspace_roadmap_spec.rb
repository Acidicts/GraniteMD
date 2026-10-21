require 'rails_helper'

RSpec.describe "Workspace roadmap editor", type: :request do
  let!(:user) { create(:user) }
  let!(:workspace) do
    Workspace.create!(name: "Roadmaps", feature_set: "personal").tap { |ws| ws.users << user }
  end
  let!(:folder) { Folder.create!(name: "Product", workspace: workspace) }
  let!(:roadmap) { Roadmap.create!(name: "Launch", folder: folder) }

  describe "GET /:workspace_public_id/roadmaps/:id (change_roadmap)" do
    before { sign_in user }

    it "renders the category and task partials for each category" do
      done = RoadmapCatagory.create!(roadmap: roadmap, name: "Done")
      doing = RoadmapCatagory.create!(roadmap: roadmap, name: "In Progress")
      RoadmapTask.create!(roadmap: roadmap, header: "ship it", category: done.id, assignee: user)

      get workspace_roadmap_path(workspace.public_id, roadmap)

      expect(response).to be_successful
      expect(response.body).to include("workspace-editor")
      expect(response.body).to include("catagory_#{done.id}")
      expect(response.body).to include("catagory_#{doing.id}")
      expect(response.body).to include(user.username)
    end

    # The task card classes are what show.css hangs its styling off, so a
    # rename in the partial would silently strip the task of its layout.
    it "renders the task card markup the stylesheet targets" do
      done = RoadmapCatagory.create!(roadmap: roadmap, name: "Done")
      RoadmapTask.create!(roadmap: roadmap, header: "ship it", body: "with tests",
                          category: done.id, assignee: user)

      get workspace_roadmap_path(workspace.public_id, roadmap)

      expect(response.body).to include('class="roadmap-task"')
      expect(response.body).to include('class="roadmap-task__header"')
      expect(response.body).to include('class="roadmap-task__header-assignee-info"')
      expect(response.body).to include('id="roadmap-task-')
      expect(response.body).to include("ship it")
      expect(response.body).to include("with tests")
      expect(response.body).to include('aria-label="Drag to reorder"')
    end

    # The pencil navigates the card's own frame, so the edit action has to answer
    # with a matching frame -- not escape to a full page.
    it "links the pencil into the task frame rather than out of it" do
      done = RoadmapCatagory.create!(roadmap: roadmap, name: "Done")
      RoadmapTask.create!(roadmap: roadmap, header: "ship it", category: done.id, assignee: user)

      get workspace_roadmap_path(workspace.public_id, roadmap)

      expect(response.body).to include(edit_workspace_roadmap_item_path(workspace, roadmap, RoadmapTask.last))
      expect(response.body).not_to include('data-turbo-frame="_top"')
    end

    it "groups tasks under their own category only" do
      done = RoadmapCatagory.create!(roadmap: roadmap, name: "Done")
      RoadmapCatagory.create!(roadmap: roadmap, name: "In Progress")
      RoadmapTask.create!(roadmap: roadmap, header: "done-task", category: done.id, assignee: user)
      orphan = create(:user)
      RoadmapTask.create!(roadmap: roadmap, header: "todo-task", category: nil, assignee: orphan)

      get workspace_roadmap_path(workspace.public_id, roadmap)

      expect(response.body).to include(user.username)
      expect(response.body).not_to include(orphan.username)
    end

    # `roadmap_tasks.category` is a bare integer column, so a task on another
    # roadmap that happens to reuse the category id must not show up here.
    it "does not pull in tasks from another roadmap with a matching category id" do
      done = RoadmapCatagory.create!(roadmap: roadmap, name: "Done")
      other = Roadmap.create!(name: "Other", folder: folder)
      outsider_assignee = create(:user)
      RoadmapTask.create!(roadmap: other, header: "other-roadmap", category: done.id, assignee: outsider_assignee)

      get workspace_roadmap_path(workspace.public_id, roadmap)

      expect(response.body).not_to include(outsider_assignee.username)
    end

    it "renders when the workspace has no organisation" do
      RoadmapCatagory.create!(roadmap: roadmap, name: "Done").tap do |catagory|
        RoadmapTask.create!(roadmap: roadmap, header: "orgless", category: catagory.id, assignee: user)
      end
      expect(workspace.organisation).to be_nil

      get workspace_roadmap_path(workspace.public_id, roadmap)

      expect(response).to be_successful
      expect(response.body).to include(user.username)
    end

    it "redirects when the roadmap does not exist" do
      get workspace_roadmap_path(workspace.public_id, 0)

      expect(response).to redirect_to(dashboard_workspaces_path)
    end

    # Clicking outside an open form closes it, so the editor has to dismiss on
    # window clicks and every reveal button has to opt out of that.
    it "wires the click-outside dismissal and marks the reveal buttons" do
      RoadmapCatagory.create!(roadmap: roadmap, name: "Done")

      get workspace_roadmap_path(workspace.public_id, roadmap)

      expect(response.body).to include("click@window->workspace--roadmap-editor#dismissForms")
      expect(response.body).to include('class="newCatagoryFormContainer hidden"')
      expect(response.body).to include('class="newItemFormContainer hidden"')
      # Both the "New Catagory" button and each category's "+" button reveal a
      # form, so both need the opt-out marker.
      expect(response.body.scan("data-roadmap-editor-toggle").size).to eq(2)
      # "+" preselects its own catagory, so the button has to carry the id and
      # the item form has to submit it from a hidden field.
      catagory = roadmap.roadmap_catagory.reload.first
      expect(response.body).to include(%(data-roadmap-catagory-id="#{catagory.id}"))
      expect(response.body).to include('name="roadmap_task[category]"')
      # An icon-only button needs the base btn class to look like a button and
      # a label to be announced.
      expect(response.body).to include('class="btn btn-icon"')
      expect(response.body).to include(%(aria-label="Add item to #{catagory.name}"))
    end

    # Clicking a card opens the shared overlay dialog, so each card has to
    # carry the open action and the editor has to render the dialog shell
    # (with an empty overlay frame) plus the item URL the fetch appends to.
    it "wires task cards to the overlay dialog" do
      catagory = RoadmapCatagory.create!(roadmap: roadmap, name: "Done")
      RoadmapTask.create!(roadmap: roadmap, header: "ship it", category: catagory.id, assignee: user)

      get workspace_roadmap_path(workspace.public_id, roadmap)

      expect(response.body).to include("workspace--roadmap-editor#openOverlay")
      expect(response.body).to include("roadmap-task-overlay-dialog")
      expect(response.body).to include(%(<turbo-frame id="roadmap-task-overlay">))
      expect(response.body).to include("#{workspace_roadmap_items_path(workspace, roadmap)}/overlay")
    end
  end

  describe "POST /:workspace_public_id/roadmaps/:id/catagories (new_catagory)" do
    before { sign_in user }

    it "creates the catagory on the roadmap and appends it to the list" do
      expect {
        post workspace_roadmap_catagories_path(workspace.public_id, roadmap),
             params: { roadmap_catagory: { name: "Done" } },
             as: :turbo_stream
      }.to change(RoadmapCatagory, :count).by(1)

      catagory = roadmap.roadmap_catagory.reload.last
      expect(catagory.name).to eq("Done")
      expect(response.body).to include("catagory_#{catagory.id}")
      expect(response.body).to include(%(<turbo-stream action="append" target="roadmap-catagories-#{roadmap.id}"))
    end

    it "trims the submitted name" do
      post workspace_roadmap_catagories_path(workspace.public_id, roadmap),
           params: { roadmap_catagory: { name: "  In Progress  " } },
           as: :turbo_stream

      expect(roadmap.roadmap_catagory.reload.last.name).to eq("In Progress")
    end

    # The form sits inside the "workspace-editor" turbo frame, so failures have
    # to re-render the frame with the error instead of redirecting away from it.
    it "re-renders the editor with an error when the name is blank" do
      expect {
        post workspace_roadmap_catagories_path(workspace.public_id, roadmap),
             params: { roadmap_catagory: { name: "  " } },
             as: :turbo_stream
      }.not_to change(RoadmapCatagory, :count)

      expect(response.body).to include("workspace-editor")
      expect(response.body).to include("can&#39;t be blank")
    end

    it "re-renders the editor with an error on a duplicate name" do
      RoadmapCatagory.create!(roadmap: roadmap, name: "Done")

      expect {
        post workspace_roadmap_catagories_path(workspace.public_id, roadmap),
             params: { roadmap_catagory: { name: "Done" } },
             as: :turbo_stream
      }.not_to change(RoadmapCatagory, :count)

      expect(response.body).to include("Category Already Exists")
      # The rejected (unsaved) record must not render as an id-less category.
      expect(response.body).not_to include(%(id="catagory_"))
    end

    it "redirects when the roadmap does not exist" do
      post workspace_roadmap_catagories_path(workspace.public_id, 0),
           params: { roadmap_catagory: { name: "Done" } },
           as: :turbo_stream

      expect(response).to redirect_to(dashboard_workspaces_path)
    end

    it "redirects a user who is not a member of the workspace" do
      # SessionsController bounces anyone already signed in, so drop the
      # session the outer hook created before switching users.
      delete logout_path
      sign_in create(:user)

      post workspace_roadmap_catagories_path(workspace.public_id, roadmap),
           params: { roadmap_catagory: { name: "Done" } },
           as: :turbo_stream

      expect(response).to redirect_to(dashboard_workspaces_path)
      expect(roadmap.roadmap_catagory.reload).to be_empty
    end

    it "redirects when the public id belongs to another workspace" do
      other_ws = Workspace.create!(name: "Other", feature_set: "personal").tap { |ws| ws.users << user }

      post workspace_roadmap_catagories_path(other_ws.public_id, roadmap),
           params: { roadmap_catagory: { name: "Done" } },
           as: :turbo_stream

      expect(response).to redirect_to(dashboard_workspaces_path)
      expect(roadmap.roadmap_catagory.reload).to be_empty
    end

    it "redirects when not signed in" do
      delete logout_path

      post workspace_roadmap_catagories_path(workspace.public_id, roadmap),
           params: { roadmap_catagory: { name: "Done" } },
           as: :turbo_stream

      expect(response).to redirect_to(login_path)
      expect(roadmap.roadmap_catagory.reload).to be_empty
    end
  end

  describe "POST /:workspace_public_id/roadmaps/:id/items (new_roadmap_item)" do
    before { sign_in user }

    let!(:catagory) { RoadmapCatagory.create!(roadmap: roadmap, name: "Done") }

    it "creates the item, assigns the current user, and files it under its catagory" do
      expect {
        post workspace_roadmap_items_path(workspace.public_id, roadmap),
             params: { roadmap_task: { header: "ship it", body: "with tests", category: catagory.id } },
             as: :turbo_stream
      }.to change(RoadmapTask, :count).by(1)

      task = RoadmapTask.last
      expect(task.roadmap).to eq(roadmap)
      expect(task.assignee).to eq(user)
      expect(task.category).to eq(catagory.id)
      expect(response.body).to include(%(<turbo-stream action="append" target="catagory_#{catagory.id}"))
      expect(response.body).to include("roadmap-task")
    end

    it "trims the submitted header and body" do
      post workspace_roadmap_items_path(workspace.public_id, roadmap),
           params: { roadmap_task: { header: "  ship it  ", body: "  with tests  ", category: catagory.id } },
           as: :turbo_stream

      task = RoadmapTask.last
      expect(task.header).to eq("ship it")
      expect(task.body).to eq("with tests")
    end

    it "re-renders the editor with an error when the name is blank" do
      expect {
        post workspace_roadmap_items_path(workspace.public_id, roadmap),
             params: { roadmap_task: { header: "  ", body: "with tests", category: catagory.id } },
             as: :turbo_stream
      }.not_to change(RoadmapTask, :count)

      expect(response.body).to include("workspace-editor")
      expect(response.body).to include("can&#39;t be blank")
    end

    it "re-renders the editor with an error when no catagory is chosen" do
      expect {
        post workspace_roadmap_items_path(workspace.public_id, roadmap),
             params: { roadmap_task: { header: "ship it", body: "with tests" } },
             as: :turbo_stream
      }.not_to change(RoadmapTask, :count)

      expect(response.body).to include("must be a catagory on this roadmap")
    end

    # `category` is a bare integer column, so an id from another roadmap would
    # otherwise be accepted and file the item somewhere it can never be seen.
    it "rejects a catagory belonging to another roadmap" do
      other_roadmap = Roadmap.create!(name: "Other", folder: folder)
      foreign = RoadmapCatagory.create!(roadmap: other_roadmap, name: "Foreign")

      expect {
        post workspace_roadmap_items_path(workspace.public_id, roadmap),
             params: { roadmap_task: { header: "ship it", category: foreign.id } },
             as: :turbo_stream
      }.not_to change(RoadmapTask, :count)

      expect(response.body).to include("must be a catagory on this roadmap")
    end

    it "redirects when the roadmap does not exist" do
      post workspace_roadmap_items_path(workspace.public_id, 0),
           params: { roadmap_task: { header: "ship it", category: catagory.id } },
           as: :turbo_stream

      expect(response).to redirect_to(dashboard_workspaces_path)
    end

    it "redirects a user who is not a member of the workspace" do
      delete logout_path
      sign_in create(:user)

      post workspace_roadmap_items_path(workspace.public_id, roadmap),
           params: { roadmap_task: { header: "ship it", category: catagory.id } },
           as: :turbo_stream

      expect(response).to redirect_to(dashboard_workspaces_path)
      expect(roadmap.roadmap_tasks.reload).to be_empty
    end

    it "redirects when not signed in" do
      delete logout_path

      post workspace_roadmap_items_path(workspace.public_id, roadmap),
           params: { roadmap_task: { header: "ship it", category: catagory.id } },
           as: :turbo_stream

      expect(response).to redirect_to(login_path)
      expect(roadmap.roadmap_tasks.reload).to be_empty
    end
  end

  describe "PATCH /:workspace_public_id/roadmaps/:id/items/:item_id (update_roadmap_item)" do
    before { sign_in user }

    let!(:catagory) { RoadmapCatagory.create!(roadmap: roadmap, name: "Done") }
    let!(:other_catagory) { RoadmapCatagory.create!(roadmap: roadmap, name: "Doing") }
    let!(:task) { RoadmapTask.create!(roadmap: roadmap, header: "ship it", category: catagory.id, assignee: user) }

    it "re-categorises the item by its column index and answers json" do
      patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
            params: { roadmap_task: { category_index: 1 } },
            as: :json

      expect(response).to be_successful
      expect(task.reload.category).to eq(other_catagory.id)
      expect(response.parsed_body).to include("ok" => true, "catagory_id" => other_catagory.id)
    end

    it "resolves the index against this roadmap's categories, not another roadmap's" do
      other_roadmap = Roadmap.create!(name: "Other", folder: folder)
      RoadmapCatagory.create!(roadmap: other_roadmap, name: "Foreign")

      patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
            params: { roadmap_task: { category_index: 2 } },
            as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(task.reload.category).to eq(catagory.id)
    end

    it "answers html with a redirect" do
      patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
            params: { roadmap_task: { category_index: 1 } }

      expect(response).to redirect_to(workspace_roadmap_path(workspace, roadmap))
    end

    # to_i would quietly turn "abc" and "-1" into a valid-looking index.
    it "rejects an index that is not a plain non-negative integer" do
      [ "abc", "-1", "", "1.5", "0; DROP TABLE" ].each do |bogus|
        patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
              params: { roadmap_task: { category_index: bogus } },
              as: :json

        expect(response).to have_http_status(:unprocessable_content), "accepted #{bogus.inspect}"
        expect(task.reload.category).to eq(catagory.id)
      end
    end

    it "rejects an index past the end of the list" do
      patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
            params: { roadmap_task: { category_index: 99 } },
            as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(task.reload.category).to eq(catagory.id)
    end

    it "rejects an item that is not on this roadmap" do
      elsewhere = RoadmapTask.create!(roadmap: Roadmap.create!(name: "Other", folder: folder),
                                      header: "elsewhere", category: catagory.id, assignee: user)

      patch workspace_roadmap_item_path(workspace.public_id, roadmap, elsewhere),
            params: { roadmap_task: { category_index: 1 } },
            as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(task.reload.category).to eq(catagory.id)
    end

    it "redirects a user who is not a member of the workspace" do
      delete logout_path
      sign_in create(:user)

      patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
            params: { roadmap_task: { category_index: 1 } },
            as: :json

      expect(response).to redirect_to(dashboard_workspaces_path)
      expect(task.reload.category).to eq(catagory.id)
    end

    it "redirects when not signed in" do
      delete logout_path

      patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
            params: { roadmap_task: { category_index: 1 } },
            as: :json

      expect(response).to redirect_to(login_path)
      expect(task.reload.category).to eq(catagory.id)
    end
  end

  describe "GET /:workspace_public_id/roadmaps/:id/items/:item_id (edit_roadmap_item)" do
    before { sign_in user }

    let!(:catagory) { RoadmapCatagory.create!(roadmap: roadmap, name: "Done") }
    let!(:task) { RoadmapTask.create!(roadmap: roadmap, header: "ship it", body: "with tests",
                                      category: catagory.id, assignee: user) }

    it "renders a form carrying the current values" do
      get edit_workspace_roadmap_item_path(workspace.public_id, roadmap, task)

      expect(response).to be_successful
      expect(response.body).to include(%(<turbo-frame id="roadmap-task-#{task.id}">))
      expect(response.body).to include("ship it")
      expect(response.body).to include("with tests")
    end

    # Moving between columns is drag-only, so the form must not post a category.
    it "does not offer a category field" do
      get edit_workspace_roadmap_item_path(workspace.public_id, roadmap, task)

      expect(response.body).not_to include("roadmap_task[category]")
      expect(response.body).not_to include("roadmap_task[category_index]")
    end

    it "redirects when the item is not on this roadmap" do
      elsewhere = RoadmapTask.create!(roadmap: Roadmap.create!(name: "Other", folder: folder),
                                      header: "elsewhere", category: catagory.id, assignee: user)

      get edit_workspace_roadmap_item_path(workspace.public_id, roadmap, elsewhere)

      expect(response).to redirect_to(workspace_roadmap_path(workspace, roadmap))
    end

    # Clicking the pencil is a frame navigation: a plain HTML GET carrying a
    # Turbo-Frame header, not a turbo stream request. Turbo discards the
    # response unless it contains a frame with that exact id.
    it "answers the frame navigation with a matching frame" do
      get edit_workspace_roadmap_item_path(workspace.public_id, roadmap, task),
          headers: { "Turbo-Frame" => "roadmap-task-#{task.id}" }

      expect(response).to be_successful
      expect(response.body).to include(%(<turbo-frame id="roadmap-task-#{task.id}">))
      expect(response.body).to include('name="roadmap_task[header]"')
      expect(response.body).to include('name="roadmap_task[body]"')
      expect(response.body).to include(workspace_roadmap_item_path(workspace, roadmap, task))
    end

    it "redirects a user who is not a member of the workspace" do
      delete logout_path
      sign_in create(:user)

      get edit_workspace_roadmap_item_path(workspace.public_id, roadmap, task)

      expect(response).to redirect_to(dashboard_workspaces_path)
    end

    it "redirects when not signed in" do
      delete logout_path

      get edit_workspace_roadmap_item_path(workspace.public_id, roadmap, task)

      expect(response).to redirect_to(login_path)
    end
  end

  describe "GET /:workspace_public_id/roadmaps/:id/items/overlay/:item_id (get_roadmap_item)" do
    before { sign_in user }

    let!(:catagory) { RoadmapCatagory.create!(roadmap: roadmap, name: "Done") }
    let!(:task) { RoadmapTask.create!(roadmap: roadmap, header: "ship it", body: "with tests",
                                      category: catagory.id, assignee: user) }

    # Clicking a card fetches this HTML into the overlay dialog's frame, so it
    # must carry the task's details inside a matching frame.
    it "renders the overlay frame with the task header and body" do
      get get_workspace_roadmap_item_path(workspace.public_id, roadmap, task)

      expect(response).to be_successful
      expect(response.body).to include(%(<turbo-frame id="roadmap-task-overlay">))
      expect(response.body).to include("ship it")
      expect(response.body).to include("with tests")
    end

    it "redirects when the item is not on this roadmap" do
      elsewhere = RoadmapTask.create!(roadmap: Roadmap.create!(name: "Other", folder: folder),
                                      header: "elsewhere", category: catagory.id, assignee: user)

      get get_workspace_roadmap_item_path(workspace.public_id, roadmap, elsewhere)

      expect(response).to redirect_to(workspace_roadmap_path(workspace, roadmap))
    end

    it "redirects a user who is not a member of the workspace" do
      delete logout_path
      sign_in create(:user)

      get get_workspace_roadmap_item_path(workspace.public_id, roadmap, task)

      expect(response).to redirect_to(dashboard_workspaces_path)
    end

    it "redirects when not signed in" do
      delete logout_path

      get get_workspace_roadmap_item_path(workspace.public_id, roadmap, task)

      expect(response).to redirect_to(login_path)
    end
  end

  describe "saving the edit form" do
    before { sign_in user }

    let!(:catagory) { RoadmapCatagory.create!(roadmap: roadmap, name: "Done") }
    let!(:task) { RoadmapTask.create!(roadmap: roadmap, header: "ship it", body: "with tests",
                                      category: catagory.id, assignee: user) }

    it "updates the name and body and redirects back to the roadmap" do
      patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
            params: { roadmap_task: { header: "ship it now", body: "with tests and docs" } }

      expect(response).to redirect_to(workspace_roadmap_path(workspace, roadmap))
      expect(task.reload.header).to eq("ship it now")
      expect(task.reload.body).to eq("with tests and docs")
    end

    # The drag path sends category_index only; it must not blank the text.
    it "leaves the name and body alone when only a column is sent" do
      other = RoadmapCatagory.create!(roadmap: roadmap, name: "Doing")

      patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
            params: { roadmap_task: { category_index: 1 } },
            as: :json

      expect(response).to be_successful
      expect(task.reload.category).to eq(other.id)
      expect(task.reload.header).to eq("ship it")
      expect(task.reload.body).to eq("with tests")
    end

    it "re-renders the form with an error when the name is blank" do
      patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
            params: { roadmap_task: { header: "   ", body: "with tests" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("can&#39;t be blank")
      expect(task.reload.header).to eq("ship it")
    end

    # Saving from inside the frame must hand back a frame, not a redirect.
    it "replaces the card frame when the form is submitted as a turbo stream" do
      patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
            params: { roadmap_task: { header: "ship it now", body: "with tests" } },
            as: :turbo_stream

      expect(response.body).to include(%(target="roadmap-task-#{task.id}"))
      expect(response.body).to include("ship it now")
      expect(task.reload.header).to eq("ship it now")
    end

    it "keeps the form in the frame when a turbo stream save is rejected" do
      patch workspace_roadmap_item_path(workspace.public_id, roadmap, task),
            params: { roadmap_task: { header: "   " } },
            as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(%(<turbo-frame id="roadmap-task-#{task.id}">))
      expect(response.body).to include('name="roadmap_task[header]"')
      expect(task.reload.header).to eq("ship it")
    end
  end

  describe "access control" do
    it "redirects a user who is not a member of the workspace" do
      RoadmapCatagory.create!(roadmap: roadmap, name: "Done")
      sign_in create(:user)

      get workspace_roadmap_path(workspace.public_id, roadmap)

      expect(response).to redirect_to(dashboard_workspaces_path)
    end

    it "redirects when the public id belongs to another workspace" do
      RoadmapCatagory.create!(roadmap: roadmap, name: "Done")
      other_ws = Workspace.create!(name: "Other", feature_set: "personal").tap { |ws| ws.users << user }
      sign_in user

      get workspace_roadmap_path(other_ws.public_id, roadmap)

      expect(response).to redirect_to(dashboard_workspaces_path)
    end
  end
end
