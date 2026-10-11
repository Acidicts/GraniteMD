# == Schema Information
#
# Table name: organisations
#
#  id                          :bigint           not null, primary key
#  name                        :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  organisation_application_id :bigint
#  public_id                   :string
#
# Indexes
#
#  index_organisations_on_organisation_application_id  (organisation_application_id)
#  index_organisations_on_public_id                    (public_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (organisation_application_id => organisation_applications.id)
#
FactoryBot.define do
  factory :organisation do
    name { "MyString" }
  end
end
