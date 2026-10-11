require 'rails_helper'

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
RSpec.describe OrganisationApplication, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
