require "mailtrap"

# Production: use the Mailtrap Email API (via the mailtrap gem)
# Development uses the same live SMTP endpoint (see config/environments/development.rb)
if Rails.env.production? && ENV["MAILTRAP_API_TOKEN"].present?
  Rails.application.config.action_mailer.delivery_method = :mailtrap
  Rails.application.config.action_mailer.mailtrap_settings = {
    api_key: ENV["MAILTRAP_API_TOKEN"]
  }
end
