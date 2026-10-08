require 'rails_helper'

# == Schema Information
#
# Table name: pages
#
#  id         :bigint           not null, primary key
#  body       :text
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  folder_id  :bigint           not null
#
# Indexes
#
#  index_pages_on_folder_id  (folder_id)
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
end
