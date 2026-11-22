# == Schema Information
#
# Table name: organisation_applications
#
#  id            :bigint           not null, primary key
#  appeal_locked :boolean
#  name          :string
#  pitch         :text
#  status        :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  owner_id      :integer
#  public_id     :string
#
class OrganisationApplication < ApplicationRecord
  has_one :organisation

  belongs_to :owner, class_name: "User", foreign_key: "owner_id"

  attribute :name, :string
  attribute :status, :integer, default: 0
  attribute :appeal_locked, :boolean, default: false

  validates :name, presence: true
  validates :pitch, presence: true
  validates :owner_id, presence: true

  has_many :audits, as: :auditable, dependent: :destroy

  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2,
    queued: 3,
    created: 4
  }

  after_commit :create_org, on: :update, if: -> { saved_change_to_status?(to: "queued") && organisation.nil? }
  after_commit :queue_org, on: :update, if: -> { saved_change_to_status?(to: "approved") && organisation.nil? }

  attribute :public_id, :string, default: ""
  normalizes :public_id, with: ->(u) { u.strip.downcase }
  validates :public_id, uniqueness: { case_sensitive: false }

  before_validation :ensure_public_id, if: -> { public_id.blank? }

  class QueueOrgJob < ActiveJob::Base
    queue_as :default

    def perform(id)
      app = OrganisationApplication.find_by(id: id)
      return unless app&.approved? && app.organisation.nil?

      app.update!(status: :queued)
    end
  end

  def queue_org
    self.class::QueueOrgJob.set(wait: 5.minutes).perform_later(id)
  end

  def create_org
    ActiveRecord::Base.transaction do
      organisation = Organisation.new(name: self.name, owner: self.owner)
      organisation.users << self.owner
      organisation.save!
      organisation.audits.new(user: nil, action: "created organisation", details: {
        name: organisation.name,
        owner: self.owner&.id
      }).save!
      self.update(organisation: organisation, status: :created)
    end
  end

  private

  def ensure_public_id
    loop do
      self.public_id = SecureRandom.alphanumeric(8).downcase
      break unless self.class.where("LOWER(public_id) = ?", public_id).exists?
    end
  end
end
