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
  describe "factory" do
    it "is valid with factory attributes" do
      expect(build(:organisation_application)).to be_valid
    end

    it "persists" do
      expect { create(:organisation_application) }.to change(OrganisationApplication, :count).by(1)
    end
  end

  describe "validations" do
    it "requires a name" do
      app = build(:organisation_application, name: nil)

      expect(app).not_to be_valid
      expect(app.errors[:name]).to be_present
    end

    it "requires a pitch" do
      app = build(:organisation_application, pitch: nil)

      expect(app).not_to be_valid
      expect(app.errors[:pitch]).to be_present
    end

    it "requires an owner" do
      app = build(:organisation_application, owner_id: nil)

      expect(app).not_to be_valid
      expect(app.errors[:owner_id]).to be_present
    end
  end

  describe "status" do
    it "defaults to pending" do
      expect(OrganisationApplication.new.status).to eq("pending")
      expect(create(:organisation_application).status).to eq("pending")
    end

    it "supports the full lifecycle" do
      %w[pending approved rejected queued created].each do |state|
        expect(build(:organisation_application, status: state)).to be_valid
      end
    end
  end

  describe "#owner" do
    it "resolves the user from owner_id" do
      user = create(:user)
      app = create(:organisation_application, owner_id: user.id)

      expect(app.owner).to eq(user)
    end

    it "raises when the owner is gone" do
      app = build(:organisation_application, owner_id: -1)

      expect { app.owner }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#queue_org" do
    it "schedules the fulfilment job three hours out" do
      app = create(:organisation_application, status: :approved)

      expect { app.queue_org }
        .to have_enqueued_job(OrganisationApplication::QueueOrgJob).with(app.id).on_queue("default")

      job = ActiveJob::Base.queue_adapter.enqueued_jobs.find { |j| j[:job] == OrganisationApplication::QueueOrgJob }
      expect(job[:at]).to be_within(5).of(3.hours.from_now.to_f)
    end
  end

  describe "QueueOrgJob" do
    it "moves an approved application through queued to created" do
      app = create(:organisation_application, status: :approved)

      expect { described_class::QueueOrgJob.perform_now(app.id) }
        .to change { app.reload.status }.from("approved").to("created")
      expect(app.reload.organisation).to be_present
    end

    it "leaves non-approved applications alone" do
      rejected = create(:organisation_application, status: :rejected)

      expect { described_class::QueueOrgJob.perform_now(rejected.id) }
        .not_to change { rejected.reload.status }
    end

    it "does nothing when the application is gone" do
      expect { described_class::QueueOrgJob.perform_now(-1) }.not_to raise_error
    end

    it "does nothing once an organisation already exists" do
      app = create(:organisation_application, status: :approved)
      app.create_org
      expect(app.reload).to be_created

      # Flip back to approved without callbacks so the job sees an org present.
      app.update_column(:status, OrganisationApplication.statuses[:approved])

      expect { described_class::QueueOrgJob.perform_now(app.id) }
        .not_to change { app.reload.status }
      expect { described_class::QueueOrgJob.perform_now(app.id) }
        .not_to change(Organisation, :count)
      expect(app.reload.organisation).to be_present
    end
  end

  describe "#create_org" do
    it "creates an organisation named after the application" do
      app = create(:organisation_application, status: :queued)

      expect { app.create_org }.to change(Organisation, :count).by(1)
      expect(app.reload.organisation.name).to eq(app.name)
    end

    it "adds the owner as a member of the new organisation" do
      user = create(:user)
      app = create(:organisation_application, owner_id: user.id, status: :queued)

      app.create_org

      expect(app.reload.organisation.users).to include(user)
    end

    it "marks the application as created" do
      app = create(:organisation_application, status: :queued)

      app.create_org

      expect(app.reload.status).to eq("created")
    end
  end
end
