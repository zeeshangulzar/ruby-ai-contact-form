class ContactMailer < ApplicationMailer
  def team_notification(submission, team_email)
    @submission = submission

    prefix  = submission.urgent? ? "[URGENT]" : nil
    subject = ["[#{submission.category.capitalize}]", prefix, "New contact from #{submission.name}"].compact.join(" ")

    headers["X-MT-Category"] = submission.category

    mail(
      to:      team_email,
      from:    ENV.fetch("MAILTRAP_FROM_EMAIL", "no-reply@example.com"),
      subject: subject
    )
  end

  def auto_reply(submission)
    @submission = submission

    headers["X-MT-Category"] = submission.category

    mail(
      to:      submission.email,
      from:    ENV.fetch("MAILTRAP_FROM_EMAIL", "no-reply@example.com"),
      subject: "We received your message"
    )
  end
end
