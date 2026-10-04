# == Schema Information
#
# Table name: workspaces
#
#  id         :bigint           not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Workspace < ApplicationRecord
  has_many :users

  validates :name, presence: true
end
