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
  has_many :workspace_files, through: :folders
  has_many :roadmaps, through: :folders

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
  validate :workspace_image_content_type
  validate :workspace_image_size

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

  # Wikilink target => workspace page path, keyed by exact-case spelling:
  # each page contributes its bare name plus every suffix of
  # "<folder>/<...>/<page>". When several pages share an exact key, the
  # oldest page wins. Case-insensitive fallback lives in #wikilink_url_for
  # (and the matching JS): the exact key is tried first, then the oldest
  # key that matches case-insensitively, so [[Install]] prefers "Install"
  # while [[INSTALL]] still finds it.
  def page_link_map
    url_helpers = Rails.application.routes.url_helpers
    folders_by_id = folders.index_by(&:id)
    pages.includes(:folder).order("pages.created_at ASC, pages.id ASC").each_with_object({}) do |page, map|
      name = page.name.to_s.strip
      next if name.blank?

      url = url_helpers.workspace_page_path(self, page)
      map[name] ||= url

      segments = folder_path_segments(page.folder, folders_by_id)
      full = segments + [ name ]
      segments.each_index do |i|
        qualified = full[i..].join("/")
        next if qualified.blank?

        map[qualified] ||= url
      end
    end
  end

  # Resolve a wikilink target to a page path: exact-case match first,
  # oldest case-insensitive match as fallback (so old lowercase links keep
  # working). Returns nil when nothing matches.
  def wikilink_url_for(target)
    raw = target.to_s.strip
    return nil if raw.blank?

    map = page_link_map
    return map[raw] if map.key?(raw)

    lower = raw.downcase
    map.each { |key, url| return url if key.downcase == lower }
    nil
  end

  # Embed target => ActiveStorage blob path, keyed exactly like
  # #page_link_map (bare name plus folder-path suffixes, exact case,
  # oldest wins). Only files with an upload are listed: without a blob
  # there is nothing to embed. Powers ![[file]] embeds in the preview.
  def workspace_file_map
    url_helpers = Rails.application.routes.url_helpers
    folders_by_id = folders.index_by(&:id)
    workspace_files.includes(:folder, File_attachment: :blob)
                   .order("workspace_files.created_at ASC, workspace_files.id ASC")
                   .each_with_object({}) do |workspace_file, map|
      name = workspace_file.name.to_s.strip
      next if name.blank?
      next unless workspace_file.File.attached?

      url = url_helpers.rails_blob_path(workspace_file.File, only_path: true)
      map[name] ||= url

      segments = folder_path_segments(workspace_file.folder, folders_by_id)
      full = segments + [ name ]
      segments.each_index do |i|
        qualified = full[i..].join("/")
        next if qualified.blank?

        map[qualified] ||= url
      end
    end
  end

  # Resolve an embed target to a blob path, with the same exact-first /
  # oldest-insensitive-fallback semantics as #wikilink_url_for.
  def workspace_file_url_for(target)
    raw = target.to_s.strip
    return nil if raw.blank?

    map = workspace_file_map
    return map[raw] if map.key?(raw)

    lower = raw.downcase
    map.each { |key, url| return url if key.downcase == lower }
    nil
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

  # Folder names from the workspace root down to +folder+ (blank names
  # skipped). Uses the preloaded index so deep trees don't N+1.
  def folder_path_segments(folder, folders_by_id)
    segments = []
    visited = {}
    current = folder&.id ? (folders_by_id[folder.id] || folder) : folder
    while current && !visited[current.id]
      visited[current.id] = true
      name = current.name.to_s.strip
      segments.unshift(name) unless name.blank?
      parent_id = current.parent_id
      current = parent_id ? folders_by_id[parent_id] : nil
    end
    segments
  end

  def workspace_image_content_type
    return unless workspace_image.attached?

    type = workspace_image.blob.content_type.to_s
    unless [ "image/jpeg", "image/png", "image/gif", "image/webp" ].include?(type)
      errors.add(:workspace_image, "must be an image (jpg, png, gif, webp)")
    end
  end

  def workspace_image_size
    return unless workspace_image.attached?

    if workspace_image.byte_size >= 5.megabytes
      errors.add(:workspace_image, "must be less than 5MB")
    end
  end

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
