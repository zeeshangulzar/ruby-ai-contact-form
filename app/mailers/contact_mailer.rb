class ContactMailer < ApplicationMailer
  def team_notification(submission, team_email)
    @submission = submission

    mail(
      to:      team_email,
      from:    ENV.fetch("MAILTRAP_FROM_EMAIL", "no-reply@example.com"),
      subject: "[#{submission.category.capitalize}] New contact from #{submission.name}",
      headers: { "X-MT-Category" => submission.category }
    )
  end

  def auto_reply(submission)
    @submission = submission

    mail(
      to:      submission.email,
      from:    ENV.fetch("MAILTRAP_FROM_EMAIL", "no-reply@example.com"),
      subject: "We received your message",
      headers: { "X-MT-Category" => submission.category }
    )
  end
end
