class ContactRouter
  TEAM_EMAILS = {
    "sales"       => ENV.fetch("TEAM_EMAIL_SALES",       "sales@example.com"),
    "support"     => ENV.fetch("TEAM_EMAIL_SUPPORT",     "support@example.com"),
    "partnership" => ENV.fetch("TEAM_EMAIL_PARTNERSHIP", "partnerships@example.com"),
    "other"       => ENV.fetch("TEAM_EMAIL_OTHER",       "hello@example.com")
  }.freeze

  def self.team_email_for(category)
    TEAM_EMAILS.fetch(category, TEAM_EMAILS["other"])
  end
end
