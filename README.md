# ruby-ai-contact-form

A Ruby on Rails contact form that uses **AI classification** to route submissions to the right team and send auto-replies — all via [Mailtrap](https://mailtrap.io).

Every submission is classified into a category (`sales`, `support`, `partnership`, `spam`, or `other`) using the Anthropic API. Spam submissions are logged silently. All others trigger a team notification routed to the matching inbox, plus an auto-reply to the submitter. Emails are tagged with a `X-MT-Category` header for Mailtrap analytics.

## Features

- Contact form at `/contact` with input validation
- AI classifies each submission into: `sales`, `support`, `partnership`, `spam`, or `other`
- Team notification email routed to the correct inbox based on category
- `X-MT-Category` header set on all outgoing emails for Mailtrap dashboard analytics
- Auto-reply sent to every non-spam submitter
- Spam submissions are logged to the database but no emails are sent
- Graceful degradation — if the AI API is unavailable, category falls back to `"other"`
- All submissions stored in the database regardless of category

## Architecture

```
POST /contact
      │
      ▼
ContactSubmission (validate & save)
      │
      ▼
ContactClassifier ──► Anthropic API ──► category
      │
      ├── spam? ──► log only, no emails
      │
      └── other ──► ContactRouter ──► team_email
                          │
                          ├── ContactMailer#team_notification ──► Mailtrap (X-MT-Category header)
                          └── ContactMailer#auto_reply ──────────► Mailtrap (X-MT-Category header)
```

## Requirements

- Ruby 3.3.6
- Rails 7.2
- SQLite3
- A [Mailtrap](https://mailtrap.io) account (free tier works)
- An [Anthropic](https://console.anthropic.com) API key

## Setup

```bash
git clone https://github.com/zeeshangulzar/ruby-ai-contact-form
cd ruby-ai-contact-form

bundle install

cp .env.example .env
# Edit .env — add your Mailtrap SMTP credentials and Anthropic API key

rails db:create db:migrate
rails server
```

Open `http://localhost:3000` in your browser.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MAILTRAP_SMTP_USER` | SMTP username — Sandboxes → My Sandbox → Integrations → Ruby on Rails |
| `MAILTRAP_SMTP_PASS` | SMTP password — same location as above |
| `MAILTRAP_FROM_EMAIL` | Sender address used in all outgoing emails |
| `ANTHROPIC_API_KEY` | API key from [console.anthropic.com](https://console.anthropic.com) → API Keys |
| `TEAM_EMAIL_SALES` | Inbox for sales enquiries |
| `TEAM_EMAIL_SUPPORT` | Inbox for support requests |
| `TEAM_EMAIL_PARTNERSHIP` | Inbox for partnership enquiries |
| `TEAM_EMAIL_OTHER` | Fallback inbox for uncategorised messages |

## Email Flow

1. User submits the form at `/contact`
2. Submission is validated and saved to the database with the requester's IP address
3. `ContactClassifier` sends the name, email, and message to the Anthropic API
4. The API responds with a single category word — `sales`, `support`, `partnership`, `spam`, or `other`
5. If classified as **spam** — the submission is stored and processing stops (no emails sent)
6. For all other categories:
   - `ContactRouter` maps the category to the configured team email address
   - `ContactMailer#team_notification` sends a formatted notification to the team inbox
   - `ContactMailer#auto_reply` sends a confirmation to the submitter
   - Both emails include the `X-MT-Category` header for Mailtrap dashboard grouping
7. If the Anthropic API is unavailable — the classifier catches the error and returns `"other"` so emails still flow

## Key Files

| File | Purpose |
|------|---------|
| `app/controllers/contacts_controller.rb` | Handles form submission, orchestrates classify → save → route → mail |
| `app/services/contact_classifier.rb` | Calls the Anthropic API and returns a category string |
| `app/services/contact_router.rb` | Maps category to team email address via env vars |
| `app/mailers/contact_mailer.rb` | Sends team notification and auto-reply with `X-MT-Category` header |
| `app/models/contact_submission.rb` | Validates and persists every submission |
| `app/views/contact_mailer/` | HTML and plain-text email templates |
| `config/environments/development.rb` | Mailtrap sandbox SMTP configuration |

## Mailtrap Integration

Development uses Mailtrap Sandbox via SMTP so emails are caught without being delivered:

```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  user_name: ENV["MAILTRAP_SMTP_USER"],
  password:  ENV["MAILTRAP_SMTP_PASS"],
  address:   "sandbox.smtp.mailtrap.io",
  port:      2525,
  authentication: :login
}
```

The `X-MT-Category` header groups emails by category in the Mailtrap dashboard:

```ruby
mail(
  to:      team_email,
  subject: "[#{category}] New contact from #{name}",
  headers: { "X-MT-Category" => submission.category }
)
```

## Running Tests

```bash
bundle exec rspec
```

Tests cover:

- Model validations (presence, email format, message length, category inclusion)
- Form renders correctly
- Valid submission is saved and redirects
- Classifier result is stored on the submission record
- Spam submissions skip email delivery
- Invalid submissions re-render the form with errors

## License

MIT License — see [LICENSE](LICENSE) for details.
