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
class OrganisationApplication < ApplicationRecord
  has_one :organisation

  attribute :name, :string
  attribute :owner_id, :integer
  attribute :status, :integer, default: 0

  validates :name, presence: true
  validates :pitch, presence: true
  validates :owner_id, presence: true

  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2,
    queued: 3,
    created: 4
  }

  after_commit :create_org, on: :update, if: -> { saved_change_to_status?(to: "queued") && organisation.nil? }
  after_commit :queue_org, on: :update, if: -> { saved_change_to_status?(to: "approved") && organisation.nil? }

  class QueueOrgJob < ActiveJob::Base
    queue_as :default

    def perform(id)
      app = OrganisationApplication.find_by(id: id)
      return unless app&.approved? && app.organisation.nil?

      app.update!(status: :queued)
    end
  end

  def queue_org
    self.class::QueueOrgJob.set(wait: 3.hours).perform_later(id)
  end

  def create_org
    organisation = Organisation.new(name: self.name)
    organisation.users << self.owner
    organisation.save!
    self.update(organisation: organisation, status: :created)
  end

  def owner
    User.find(self.owner_id)
  end
end
