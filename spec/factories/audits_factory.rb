# == Schema Information
#
# Table name: audits
#
#  id             :bigint           not null, primary key
#  action         :string           not null
#  auditable_type :string
#  details        :json
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  auditable_id   :bigint
#  user_id        :bigint
#
# Indexes
#
#  index_audits_on_action     (action)
#  index_audits_on_auditable  (auditable_type,auditable_id)
#  index_audits_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :audit do
    action { "create" }
    details { {} }
    association :user
  end
end
