class EmailMailerPreview < ActionMailer::Preview
  def send_email
    EmailMailer.send_email(
      to: "you@example.com",
      subject: "Preview",
      body: "<p>Hello preview</p>"
    )
  end
end
