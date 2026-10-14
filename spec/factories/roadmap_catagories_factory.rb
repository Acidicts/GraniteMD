# == Schema Information
#
# Table name: roadmap_catagories
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  roadmap_id :bigint           not null
#
# Indexes
#
#  index_roadmap_catagories_on_roadmap_id  (roadmap_id)
#
# Foreign Keys
#
#  fk_rails_...  (roadmap_id => roadmaps.id)
#
FactoryBot.define do
  factory :roadmap_catagory do
    sequence(:name) { |n| "Category #{n}" }
    roadmap
  end
end
