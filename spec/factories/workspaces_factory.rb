# == Schema Information
#
# Table name: workspaces
#
#  id         :bigint           not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :workspace do
    name { "Test Workspace" }
  end
end
