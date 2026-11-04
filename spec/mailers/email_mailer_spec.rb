require "rails_helper"

RSpec.describe EmailMailer, type: :mailer do
  describe "#send_email" do
    let(:mail) do
      EmailMailer.send_email(to: "reader@example.com", subject: "Codes", body: "<p>Your code is 1234</p>")
    end

    def html_for(body)
      EmailMailer.send_email(to: "reader@example.com", subject: "x", body: body).html_part.body.decoded
    end

    it "builds a multipart message with the given recipient and subject" do
      expect(mail).to be_multipart
      expect(mail.to).to eq([ "reader@example.com" ])
      expect(mail.subject).to eq("Codes")
    end

    it "includes the content in both the text and html parts" do
      expect(mail.text_part.body.decoded).to include("Your code is 1234")
      expect(mail.html_part.body.decoded).to include("<p>Your code is 1234</p>")
    end

    it "strips unsafe tags from the html part" do
      html = html_for("<p>Hi</p><script>alert(1)</script>")

      expect(html).to include("<p>Hi</p>")
      expect(html).not_to include("<script")
    end

    it "renders plain text as escaped html" do
      expect(html_for("a < b & c")).to include("a &lt; b &amp; c")
    end

    it "keeps safe links intact" do
      html = html_for('<a href="https://example.com/dashboard">here</a>')

      expect(html).to include('<a href="https://example.com/dashboard">here</a>')
    end

    it "strips javascript: links" do
      html = html_for('<a href="javascript:alert(1)">click</a>')

      expect(html).not_to include("javascript:")
    end

    it "keeps the link in the plain-text part readable" do
      text = EmailMailer.send_email(
        to: "reader@example.com",
        subject: "Welcome to GraniteMD",
        body: 'Welcome, get started <a href="https://example.com/dashboard">here</a>'
      ).text_part.body.decoded

      expect(text).to include("get started")
      expect(text).not_to include("<a ")
    end
  end
end
