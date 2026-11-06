class EmailMailer < ApplicationMailer
  def send_email(to:, subject:, body:)
    @body = body.to_s

    attachments.inline["logo.png"] = {
      mime_type: "image/png",
      content: File.binread(Rails.root.join("app/assets/images/logo-email.png"))
    }

    # Force a fresh thread: never send threading headers, always use a unique
    # Message-ID. (Gmail still groups identical subjects visually in
    # Conversation View — that can only be avoided with unique subjects.)
    headers["In-Reply-To"] = nil
    headers["References"] = nil
    headers["Message-ID"] = "<#{SecureRandom.uuid}@#{Granitemd.app_host}>"
    headers["X-Entity-Ref-ID"] = "general-email-#{SecureRandom.uuid}"

    mail(to: to, subject: subject)
  end
end
