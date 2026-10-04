require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#send_email" do
    # Mail is queued rather than delivered inline, so the jobs have to be run
    # for the delivery assertions to observe anything.
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper

    before do
      ActionMailer::Base.deliveries.clear
      clear_enqueued_jobs
    end

    it "queues a multipart email to a raw address" do
      assert_enqueued_emails 1 do
        helper.send_email("reader@example.com", "Welcome", "<p>Hello there</p>")
      end

      perform_enqueued_jobs

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "reader@example.com" ])
      expect(mail.subject).to eq("Welcome")
      expect(mail.from).to eq([ ENV.fetch("MAIL_FROM", "no-reply@granitemd.local") ])
      expect(mail.text_part.body.encoded).to include("Hello there")
      expect(mail.html_part.body.encoded).to include("<p>Hello there</p>")
    end

    it "accepts a recipient object that responds to #email" do
      perform_enqueued_jobs do
        helper.send_email(Struct.new(:email).new("someone@example.com"), "Subject", "Body")
      end

      expect(ActionMailer::Base.deliveries.last.to).to eq([ "someone@example.com" ])
    end

    it "sends nothing when the recipient or subject is blank" do
      helper.send_email(nil, "Subject", "Body")
      helper.send_email("reader@example.com", " ", "Body")

      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
