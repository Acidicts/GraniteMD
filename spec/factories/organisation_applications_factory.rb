# == Schema Information
#
# Table name: organisation_applications
#
#  id         :bigint           not null, primary key
#  name       :string
#  pitch      :text
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :integer
#
FactoryBot.define do
  factory :organisation_application do
    name { "Acme Org" }
    pitch { "We need a shared workspace for our team." }
    owner_id { create(:user).id }
    status { :pending }
  end
end
