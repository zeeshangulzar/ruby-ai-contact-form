class ContactSubmission < ApplicationRecord
  validates :name,    presence: true, length: { maximum: 100 }
  validates :email,   presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true, length: { minimum: 10, maximum: 5000 }
  validates :category, inclusion: { in: %w[sales support partnership spam other] }, allow_nil: true
end
