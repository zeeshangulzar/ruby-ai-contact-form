require "net/smtp"

class DeliverMailJob < ApplicationJob
  queue_as :default

  retry_on Net::SMTPUnknownError, Net::SMTPServerBusy, attempts: 100, wait: 5.seconds

  def perform(mailer, action, submission_id, *args)
    submission = ContactSubmission.find(submission_id)
    mailer.constantize.public_send(action, submission, *args).deliver_now
  end
end
