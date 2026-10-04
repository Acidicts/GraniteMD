class EmailMailer < ApplicationMailer
  def send_email(to:, subject:, body:)
    @body = body.to_s

    mail(to: to, subject: subject)
  end
end
