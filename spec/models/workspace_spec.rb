require 'rails_helper'

# == Schema Information
#
# Table name: workspaces
#
#  id              :bigint           not null, primary key
#  feature_set     :integer
#  name            :string           default(""), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organisation_id :bigint
#  owner_id        :integer
#  public_id       :string
#
# Indexes
#
#  index_workspaces_on_organisation_id  (organisation_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#
RSpec.describe Workspace, type: :model do
  describe "validations" do
    it "is valid with a name" do
      expect(build(:workspace)).to be_valid
    end

    it "requires a name" do
      workspace = build(:workspace, name: "")

      expect(workspace).not_to be_valid
      expect(workspace.errors[:name]).to be_present
    end

    it "does not save without a name" do
      workspace = build(:workspace, name: nil)

      expect(workspace.save).to be(false)
      expect(workspace.persisted?).to be(false)
    end
  end

  describe "defaults" do
    it "starts with an empty name" do
      expect(Workspace.new.name).to eq("")
    end
  end

  describe "associations" do
    it "shares users through the membership join table" do
      workspace = create(:workspace)
      user = create(:user)

      workspace.users << user

      expect(workspace.users).to contain_exactly(user)
      expect(Workspace.reflect_on_association(:users).macro).to eq(:has_and_belongs_to_many)
    end
  end

  describe "#page_link_map" do
    it "maps exact-case page names to page paths" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Docs")
      page = create(:page, name: "Getting Started", folder: folder)

      expected = Rails.application.routes.url_helpers.workspace_page_path(workspace, page)

      expect(workspace.page_link_map).to eq({
        "Getting Started" => expected,
        "Docs/Getting Started" => expected
      })
    end

    it "resolves same-case-different pages in the same folder" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Docs")
      lower = create(:page, name: "yay", folder: folder, created_at: 2.days.ago)
      upper = create(:page, name: "Yay", folder: folder, created_at: 1.day.ago)

      map = workspace.page_link_map
      helpers = Rails.application.routes.url_helpers

      expect(map["yay"]).to eq(helpers.workspace_page_path(workspace, lower))
      expect(map["Yay"]).to eq(helpers.workspace_page_path(workspace, upper))
      expect(map["Docs/yay"]).to eq(helpers.workspace_page_path(workspace, lower))
      expect(map["Docs/Yay"]).to eq(helpers.workspace_page_path(workspace, upper))
    end

    it "picks the oldest page when exact names collide" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Docs")
      oldest = create(:page, name: "Ideas", folder: folder, created_at: 2.days.ago)
      create(:page, name: "Ideas", folder: folder, created_at: 1.day.ago)
      other_workspace = create(:workspace)
      other_folder = create(:folder, workspace: other_workspace)
      create(:page, name: "Ideas", folder: other_folder)

      map = workspace.page_link_map

      expect(map["Ideas"]).to eq(Rails.application.routes.url_helpers.workspace_page_path(workspace, oldest))
      expect(map["Docs/Ideas"]).to eq(Rails.application.routes.url_helpers.workspace_page_path(workspace, oldest))
      expect(map.values).to all(start_with("/workspace/"))
    end

    it "resolves same-name pages via folder-qualified paths" do
      workspace = create(:workspace)
      guides = create(:folder, workspace: workspace, name: "Guides")
      setup = create(:folder, workspace: workspace, name: "Setup")
      guides_page = create(:page, name: "Install", folder: guides, created_at: 2.days.ago)
      setup_page = create(:page, name: "Install", folder: setup, created_at: 1.day.ago)

      map = workspace.page_link_map
      helpers = Rails.application.routes.url_helpers

      expect(map["Install"]).to eq(helpers.workspace_page_path(workspace, guides_page))
      expect(map["Guides/Install"]).to eq(helpers.workspace_page_path(workspace, guides_page))
      expect(map["Setup/Install"]).to eq(helpers.workspace_page_path(workspace, setup_page))
    end

    it "matches qualified paths through nesting" do
      workspace = create(:workspace)
      parent = create(:folder, workspace: workspace, name: "Guides")
      child = create(:folder, workspace: workspace, name: "Setup", parent: parent)
      page = create(:page, name: "Install", folder: child)

      map = workspace.page_link_map
      expected = Rails.application.routes.url_helpers.workspace_page_path(workspace, page)

      expect(map["Guides/Setup/Install"]).to eq(expected)
      expect(map["Setup/Install"]).to eq(expected)
      expect(map["Install"]).to eq(expected)
    end
  end

  describe "#wikilink_url_for" do
    it "resolves exact case, then falls back case-insensitively to the oldest" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Docs")
      page = create(:page, name: "Meeting Notes", folder: folder)

      expected = Rails.application.routes.url_helpers.workspace_page_path(workspace, page)

      expect(workspace.wikilink_url_for("Meeting Notes")).to eq(expected)
      expect(workspace.wikilink_url_for("meeting notes")).to eq(expected)
      expect(workspace.wikilink_url_for("MEETING NOTES")).to eq(expected)
      expect(workspace.wikilink_url_for("Docs/Meeting Notes")).to eq(expected)
      expect(workspace.wikilink_url_for("docs/meeting notes")).to eq(expected)
    end

    it "sends each casing to its own page and unknown casing to the oldest" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Docs")
      lower = create(:page, name: "yay", folder: folder, created_at: 2.days.ago)
      upper = create(:page, name: "Yay", folder: folder, created_at: 1.day.ago)

      helpers = Rails.application.routes.url_helpers

      expect(workspace.wikilink_url_for("yay")).to eq(helpers.workspace_page_path(workspace, lower))
      expect(workspace.wikilink_url_for("Yay")).to eq(helpers.workspace_page_path(workspace, upper))
      expect(workspace.wikilink_url_for("YAY")).to eq(helpers.workspace_page_path(workspace, lower))
      expect(workspace.wikilink_url_for("Docs/yay")).to eq(helpers.workspace_page_path(workspace, lower))
      expect(workspace.wikilink_url_for("docs/YAY")).to eq(helpers.workspace_page_path(workspace, lower))
    end

    it "returns nil for blank targets and unknown pages" do
      workspace = create(:workspace)

      expect(workspace.wikilink_url_for("  ")).to be_nil
      expect(workspace.wikilink_url_for("Nope")).to be_nil
      expect(workspace.wikilink_url_for("Docs/Nope")).to be_nil
    end
  end

  describe "#file_index" do
    def attach_upload(workspace_file, filename: "photo.png")
      workspace_file.file.attach(
        io: StringIO.new("fake-image-bytes"),
        filename: filename,
        content_type: "image/png"
      )
      workspace_file
    end

    it "lists the files with an upload, their folder and their preview url" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Assets", parent: workspace.folder)
      file = attach_upload(create(:workspace_file, name: "photo.png", folder: folder))
      preview_url = Rails.application.routes.url_helpers.workspace_file_path(workspace, file)
      expected = [ { id: file.id, name: "photo.png", folder: "Assets", url: preview_url } ]

      expect(workspace.file_index).to eq(expected)
    end

    it "skips files without an upload" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Assets", parent: workspace.folder)
      create(:workspace_file, name: "missing.png", folder: folder)

      expect(workspace.file_index).to eq([])
    end

    it "leaves the workspace root out of the folder" do
      workspace = create(:workspace)
      file = attach_upload(create(:workspace_file, name: "photo.png", folder: workspace.folder))

      expect(workspace.file_index.first[:folder]).to eq("")
    end

    it "does not list the files of another workspace" do
      workspace = create(:workspace)
      other = create(:workspace)
      attach_upload(create(:workspace_file, name: "photo.png", folder: create(:folder, workspace: other)))

      expect(workspace.file_index).to eq([])
    end
  end

  describe "#workspace_file_map" do
    def attach_upload(workspace_file, filename: "photo.png")
      workspace_file.file.attach(
        io: StringIO.new("fake-image-bytes"),
        filename: filename,
        content_type: "image/png"
      )
      workspace_file
    end

    def blob_path(workspace_file)
      Rails.application.routes.url_helpers.rails_blob_path(workspace_file.file, only_path: true)
    end

    it "maps exact-case file names with uploads to blob paths" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Assets")
      file = attach_upload(create(:workspace_file, name: "photo.png", folder: folder))

      expect(workspace.workspace_file_map).to eq({
        "photo.png" => blob_path(file),
        "Assets/photo.png" => blob_path(file)
      })
    end

    it "skips files without an upload" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Assets")
      create(:workspace_file, name: "missing.png", folder: folder)

      expect(workspace.workspace_file_map).to eq({})
    end

    it "picks the oldest file when exact names collide" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Assets")
      oldest = attach_upload(create(:workspace_file, name: "logo.png", folder: folder, created_at: 2.days.ago))
      attach_upload(create(:workspace_file, name: "logo.png", folder: folder, created_at: 1.day.ago))
      other_workspace = create(:workspace)
      attach_upload(create(:workspace_file, name: "logo.png", folder: create(:folder, workspace: other_workspace)))

      map = workspace.workspace_file_map

      expect(map["logo.png"]).to eq(blob_path(oldest))
      expect(map["Assets/logo.png"]).to eq(blob_path(oldest))
    end

    it "resolves same-name files via folder-qualified paths" do
      workspace = create(:workspace)
      icons = create(:folder, workspace: workspace, name: "Icons")
      shots = create(:folder, workspace: workspace, name: "Shots")
      icons_file = attach_upload(create(:workspace_file, name: "home.png", folder: icons, created_at: 2.days.ago))
      shots_file = attach_upload(create(:workspace_file, name: "home.png", folder: shots, created_at: 1.day.ago))

      map = workspace.workspace_file_map

      expect(map["home.png"]).to eq(blob_path(icons_file))
      expect(map["Icons/home.png"]).to eq(blob_path(icons_file))
      expect(map["Shots/home.png"]).to eq(blob_path(shots_file))
    end
  end

  describe "#workspace_file_url_for" do
    def attach_upload(workspace_file, filename: "photo.png")
      workspace_file.file.attach(
        io: StringIO.new("fake-image-bytes"),
        filename: filename,
        content_type: "image/png"
      )
      workspace_file
    end

    def blob_path(workspace_file)
      Rails.application.routes.url_helpers.rails_blob_path(workspace_file.file, only_path: true)
    end

    it "resolves exact case, then falls back case-insensitively to the oldest" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Assets")
      file = attach_upload(create(:workspace_file, name: "Photo.png", folder: folder))

      expect(workspace.workspace_file_url_for("Photo.png")).to eq(blob_path(file))
      expect(workspace.workspace_file_url_for("photo.png")).to eq(blob_path(file))
      expect(workspace.workspace_file_url_for("PHOTO.PNG")).to eq(blob_path(file))
      expect(workspace.workspace_file_url_for("Assets/Photo.png")).to eq(blob_path(file))
      expect(workspace.workspace_file_url_for("assets/photo.png")).to eq(blob_path(file))
    end

    it "returns nil for blank targets, unknown files and uploads missing" do
      workspace = create(:workspace)
      folder = create(:folder, workspace: workspace, name: "Assets")
      create(:workspace_file, name: "missing.png", folder: folder)

      expect(workspace.workspace_file_url_for("  ")).to be_nil
      expect(workspace.workspace_file_url_for("Nope.png")).to be_nil
      expect(workspace.workspace_file_url_for("missing.png")).to be_nil
    end
  end
end
