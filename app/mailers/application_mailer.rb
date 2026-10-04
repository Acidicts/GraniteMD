class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "no-reply@granitemd.local") }
  layout "mailer"
end
