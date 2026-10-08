# == Schema Information
#
# Table name: workspaces
#
#  id              :bigint           not null, primary key
#  feature_set     :integer
#  name            :string           default(""), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organisation_id :bigint
#  owner_id        :integer
#
# Indexes
#
#  index_workspaces_on_organisation_id  (organisation_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#
class Workspace < ApplicationRecord
  belongs_to :organisation, optional: true
  belongs_to :owner, class_name: "User", optional: true
  has_and_belongs_to_many :users

  has_many :folders, dependent: :destroy
  has_many :pages, through: :folders

  has_one_attached :workspace_image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 300, 200 ], format: :webp, saver: { quality: 75, strip: true }
    attachable.variant :display, resize_to_limit: [ 900, 600 ], format: :webp, saver: { quality: 78, strip: true }
  end

  enum :feature_set, {
    personal: 0,
    education: 1,
    business: 2
  }

  validates :name, presence: true
  validates :feature_set, presence: true

  before_validation :assign_default_owner

  def display_owner_or_organisation
    if self.owner.nil? && self.organisation.presence
      organisation&.name
    elsif self.owner.presence
      owner&.username
    else
      "Unassigned"
    end
  end

  def get_storage_use
    self.pages.sum(Arel.sql("pg_column_size(pages)"))
  end

  def available_storage
    (self.owner&.available_storage || 0).to_i
  end

  private

  def assign_default_owner
    return if owner_id.present? || self.organisation.present?
    # Use user_ids (a separate query) rather than users.first so we do not
    # load and cache an empty users collection on a fresh record. Caching
    # [] here would make a later `user.workspaces << workspace` appear
    # missing from `workspace.users` until reload.
    first_id = user_ids.first
    self.owner_id ||= first_id if first_id
  end
end
