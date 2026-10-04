module ApplicationHelper
  def send_email(target, subject, body)
    to = target.respond_to?(:email) ? target.email : target
    return if to.blank? || subject.blank?

    # Queued rather than delivered inline: an SMTP outage must not turn the
    # request into a 500, and the caller should not pay SMTP latency.
    EmailMailer.send_email(to: to, subject: subject.to_s, body: body.to_s).deliver_later
  end
end
