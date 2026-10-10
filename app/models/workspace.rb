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
#  public_id       :string
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
  has_one :folder, -> { where(parent_id: nil).order(:created_at) }, class_name: "Folder", inverse_of: :workspace
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

  normalizes :public_id, with: ->(u) { u.strip.downcase }
  validates :public_id, uniqueness: { case_sensitive: false }

  before_validation :ensure_public_id, if: -> { public_id.blank? }

  # Short URLs (/workspace/:public_id, /dashboard/workspaces/:public_id) use
  # the public id. Lookups must accept either the numeric id or the public id.
  def to_param
    public_id.presence || id&.to_s
  end

  validates :name, presence: true
  validates :feature_set, presence: true

  before_validation :assign_default_owner
  after_create :ensure_root_folder

  # Single root folder for the workspace. All other folders and files
  # live inside it (nested via Folder#parent / Folder#folders).
  def root_folder
    folder || ensure_root_folder
  end

  def ensure_root_folder
    roots = folders.where(parent_id: nil).order(:created_at).to_a
    root = roots.first || folders.create!(name: name.presence || "Untitled workspace")
    # Consolidate legacy workspaces that ended up with multiple roots:
    # nest any extra roots under the first so the tree stays single-rooted.
    if roots.size > 1
      roots[1..].each { |extra| extra.update!(parent: root) }
    end
    root
  end

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

  # Finds by numeric id or public_id (case-insensitive).
  # to_param emits public_id, so find() by itself would break for slugs.
  def self.find_by_id_or_public_id!(identifier)
    find_by(id: identifier) || find_by("LOWER(public_id) = ?", identifier.to_s.downcase)
  end

  def self.find_by_id_or_public_id(identifier)
    find_by_id_or_public_id!(identifier)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  private

  def ensure_public_id
    loop do
      self.public_id = SecureRandom.alphanumeric(8).downcase
      break unless self.class.where("LOWER(public_id) = ?", public_id).exists?
    end
  end

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
