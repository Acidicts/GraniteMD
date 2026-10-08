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
FactoryBot.define do
  factory :page do
    body { "MyText" }
    name { "MyString" }
    folder
  end
end
