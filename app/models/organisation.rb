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
class Organisation < ApplicationRecord
  belongs_to :organisation_application, optional: true
  DEFAULT_STORAGE = 50.megabytes

  attribute :name, :string

  has_and_belongs_to_many :users
  has_many :workspaces

  normalizes :public_id, with: ->(u) { u.strip.downcase }
  validates :public_id, uniqueness: { case_sensitive: false }

  before_validation :ensure_public_id, if: -> { public_id.blank? }

  # Short URLs (/dashboard/organisations/:public_id) use the public id,
  # mirroring Workspace#to_param.
  def to_param
    public_id.presence || id&.to_s
  end

  def total_storage
    DEFAULT_STORAGE
  end

  private

  def ensure_public_id
    loop do
      self.public_id = SecureRandom.alphanumeric(8).downcase
      break unless self.class.where("LOWER(public_id) = ?", public_id).exists?
    end
  end
end
