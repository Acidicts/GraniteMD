# == Schema Information
#
# Table name: roadmaps
#
#  id         :bigint           not null, primary key
#  body       :text
#  header     :text
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  folder_id  :bigint           not null
#
# Indexes
#
#  index_roadmaps_on_folder_id  (folder_id)
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => folders.id)
#
FactoryBot.define do
  factory :roadmap do
    name { "MyString" }
    body { "MyText" }
    header { "MyText" }
    folder
  end
end
