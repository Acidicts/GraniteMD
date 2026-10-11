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
    status { 1 }
    name { "MyString" }
    owner_id { 1 }
  end
end
