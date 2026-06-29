class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILTRAP_FROM_EMAIL", "no-reply@example.com")
  layout "mailer"
end
