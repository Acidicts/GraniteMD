require 'rails_helper'

# == Schema Information
#
# Table name: pages
#
#  id            :bigint           not null, primary key
#  body          :text
#  name          :string
#  search_vector :tsvector
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  folder_id     :bigint           not null
#
# Indexes
#
#  index_pages_on_folder_id      (folder_id)
#  index_pages_on_search_vector  (search_vector) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => folders.id)
#
RSpec.describe Page, type: :model do
  describe "factory" do
    it "is valid with factory attributes" do
      expect(build(:page)).to be_valid
    end

    it "persists with a folder" do
      expect { create(:page) }.to change(Page, :count).by(1)
    end
  end

  describe "validations" do
    it "requires a name" do
      page = build(:page, name: nil)

      expect(page).not_to be_valid
      expect(page.errors[:name]).to be_present
    end

    it "does not save without a name" do
      page = build(:page, name: "")

      expect(page.save).to be(false)
      expect(page.persisted?).to be(false)
    end
  end

  describe "defaults" do
    it "defaults body to an empty string" do
      expect(Page.new.body).to eq("")
    end

    it "keeps an explicitly assigned body" do
      expect(build(:page, body: "Hello").body).to eq("Hello")
    end
  end

  describe "associations" do
    it "belongs to a folder" do
      expect(Page.reflect_on_association(:folder).macro).to eq(:belongs_to)
    end

    it "requires a folder" do
      page = build(:page, folder: nil)

      expect(page).not_to be_valid
      expect(page.errors[:folder]).to be_present
    end

    it "reaches its workspace through the folder" do
      expect(Page.reflect_on_association(:workspace).macro).to eq(:has_one)
      expect(Page.reflect_on_association(:workspace).options[:through]).to eq(:folder)
    end

    it "returns the folder's workspace" do
      page = create(:page)

      expect(page.workspace).to eq(page.folder.workspace)
    end
  end

  describe ".search" do
    it "finds a page by a word in its body" do
      page = create(:page, name: "Notes", body: "The quickstart covers the panel setup")

      expect(Page.search("panel")).to include(page)
    end

    it "finds a page by a word in its name" do
      page = create(:page, name: "Install guide", body: "Nothing to see here")

      expect(Page.search("install")).to include(page)
    end

    it "matches the start of a word, so a prefix finds the longer word" do
      page = create(:page, name: "Notes", body: "Run the installer first")

      expect(Page.search("install")).to include(page)
    end

    it "matches every word of the query" do
      page = create(:page, name: "Notes", body: "The quickstart covers the panel setup")

      expect(Page.search("quickstart panel")).to include(page)
    end

    it "widens the query to any word when nothing matches every word" do
      page = create(:page, name: "Notes", body: "The quickstart covers the panel setup")

      expect(Page.search("quickstart zebra")).to include(page)
    end

    it "returns nothing for a blank query" do
      create(:page, name: "Notes", body: "The quickstart covers the panel setup")

      expect(Page.search("")).to be_empty
      expect(Page.search("   ")).to be_empty
      expect(Page.search(nil)).to be_empty
    end

    it "returns nothing for a query without any word in it" do
      create(:page, name: "Notes", body: "The quickstart covers the panel setup")

      expect(Page.search("?!")).to be_empty
    end

    it "does not match pages without any of the words" do
      page = create(:page, name: "Notes", body: "The quickstart covers the panel setup")
      other = create(:page, name: "Other", body: "Nothing relevant here")

      results = Page.search("panel zebra").to_a

      expect(results).to include(page)
      expect(results).not_to include(other)
    end

    it "is not confused by the words of a query" do
      create(:page, name: "Notes", body: "The quickstart covers the panel setup")

      expect { Page.search("panel & zebra").to_a }.not_to raise_error
    end

    it "ranks the page that matches the query better first" do
      weak = create(:page, name: "Notes", body: "panel")
      strong = create(:page, name: "Notes", body: "panel panel panel setup")

      expect(Page.search("panel").first).to eq(strong)
      expect(Page.search("panel")).to include(weak)
    end
  end

  describe "#search_snippet" do
    it "returns the text around the matched word" do
      page = build(:page, body: "The quickstart covers the panel setup nicely")

      expect(page.search_snippet("panel")).to include("panel setup")
    end

    it "returns the start of the body when nothing matches" do
      page = build(:page, body: "The quickstart covers the panel setup")

      expect(page.search_snippet("zebra")).to eq("The quickstart covers the panel setup")
    end

    it "is empty for an empty body" do
      expect(build(:page, body: "").search_snippet("panel")).to eq("")
    end

    it "keeps the excerpt short" do
      page = build(:page, body: "#{"word " * 200}needle")

      expect(page.search_snippet("needle").length).to be <= 200
    end
  end
end
