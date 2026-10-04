require "rails_helper"

RSpec.describe EmailMailer, type: :mailer do
  describe "#send_email" do
    let(:mail) { EmailMailer.send_email(to: "reader@example.com", subject: "Codes", body: "<p>Your code is 1234</p>") }

    it "builds a multipart message with the given subject" do
      expect(mail.to).to eq([ "reader@example.com" ])
      expect(mail.subject).to eq("Codes")
      expect(mail.text_part.body.encoded).to include("Your code is 1234")
    end

    it "sanitizes markup in the html part" do
      expect(mail.html_part.body.encoded).to include("<p>Your code is 1234</p>")
      expect(mail.html_part.body.encoded).not_to include("<script")
    end

    it "strips unsafe tags from the html part" do
      html = EmailMailer.send_email(to: "reader@example.com", subject: "x",
                                    body: "<p>Hi</p><script>alert(1)</script>").html_part.body.encoded

      expect(html).to include("<p>Hi</p>")
      expect(html).not_to include("<script>alert(1)</script>")
    end

    it "renders plain text as escaped html" do
      html = EmailMailer.send_email(to: "reader@example.com", subject: "x",
                                    body: "a < b & c").html_part.body.encoded

      expect(html).to include("a &lt; b &amp; c")
    end
  end
end
