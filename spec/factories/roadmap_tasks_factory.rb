# == Schema Information
#
# Table name: roadmap_tasks
#
#  id          :bigint           not null, primary key
#  body        :text
#  category    :integer
#  header      :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  assignee_id :bigint
#  roadmap_id  :bigint           not null
#
# Indexes
#
#  index_roadmap_tasks_on_assignee_id  (assignee_id)
#  index_roadmap_tasks_on_roadmap_id   (roadmap_id)
#
# Foreign Keys
#
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (roadmap_id => roadmaps.id)
#
FactoryBot.define do
  factory :roadmap_task do
    header { "MyString" }
    body { "MyText" }
    category { nil }
    # was `roadmap { nil }`, which made every un-overridden build blow up on the
    # NOT NULL roadmap_id.
    roadmap
    # Named association, so it has to be spelled out -- a bare `assignee` reads
    # as a trait, and the association's class is User, not Assignee.
    association :assignee, factory: :user
  end
end
