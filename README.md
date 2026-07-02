# ruby-ai-contact-form

A Ruby on Rails contact form that uses **AI classification** to route submissions to the right team and send auto-replies — all via [Mailtrap](https://mailtrap.io).

Every submission is classified into a category (`sales`, `support`, `partnership`, `spam`, or `other`) and an urgency flag (`urgent` or `normal`) using the Anthropic API. Spam submissions are logged silently. All others trigger a team notification routed to the matching inbox, plus an auto-reply to the submitter. Emails are tagged with a `X-MT-Category` header for Mailtrap analytics.

## Features

- Contact form at `/contact` with input validation
- AI classifies each submission into: `sales`, `support`, `partnership`, `spam`, or `other`, with urgency detection (`urgent` / `normal`)
- Urgent submissions are flagged with `[URGENT]` in the team notification subject line
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
ContactClassifier ──► Anthropic API ──► { category, urgent }
      │
      ├── spam? ──► log only, no emails
      │
      └── other ──► ContactRouter ──► team_email
                          │
                          ├── DeliverMailJob ──► ContactMailer#team_notification ──► Mailtrap ([URGENT] subject, X-MT-Category)
                          └── DeliverMailJob ──► ContactMailer#auto_reply ──────────► Mailtrap (X-MT-Category header)
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
# Edit .env — add your Mailtrap API token, Anthropic API key, and team emails

rails db:create db:migrate
rails server
```

Open `http://localhost:3000` in your browser.

### Mailtrap setup

This app uses **Mailtrap Email Sending** (real delivery, not the Sandbox testing product):

1. Sign in to [Mailtrap](https://mailtrap.io) → **Email Sending** → **Sending Domains**
2. Either add and verify your own domain, or use the free **`demomailtrap.co`** demo domain that is pre-created for every account
   - The demo domain can only deliver to your Mailtrap account email address — great for local testing, not for reaching real users
3. Go to **Settings** → **API Tokens** → **Add API Token** and give it the **Admin** permission on your sending domain
4. Copy the token into `.env` as `MAILTRAP_API_TOKEN`
5. Set `MAILTRAP_FROM_EMAIL` to a sender on your verified domain (e.g. `hello@demomailtrap.co`)

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MAILTRAP_API_TOKEN` | Mailtrap API token with sending permission on your domain — also used as the SMTP password |
| `MAILTRAP_FROM_EMAIL` | Verified sender address (e.g. `hello@demomailtrap.co`) |
| `ANTHROPIC_API_KEY` | API key from [console.anthropic.com](https://console.anthropic.com) → API Keys |
| `TEAM_EMAIL_SALES` | Inbox for sales enquiries |
| `TEAM_EMAIL_SUPPORT` | Inbox for support requests |
| `TEAM_EMAIL_PARTNERSHIP` | Inbox for partnership enquiries |
| `TEAM_EMAIL_OTHER` | Fallback inbox for uncategorised messages |

## Email Flow

1. User submits the form at `/contact`
2. Submission is validated and saved to the database with the requester's IP address
3. `ContactClassifier` sends the name, email, and message to the Anthropic API
4. The API responds with two words — a category (`sales`, `support`, `partnership`, `spam`, or `other`) and urgency (`urgent` or `normal`)
5. Both `category` and `urgent` are saved on the submission record
6. If classified as **spam** — the submission is stored and processing stops (no emails sent)
7. For all other categories:
   - `ContactRouter` maps the category to the configured team email address
   - `DeliverMailJob` enqueues `ContactMailer#team_notification` — subject is prefixed with `[URGENT]` when flagged
   - `DeliverMailJob` enqueues `ContactMailer#auto_reply` — sends a confirmation to the submitter
   - Both jobs retry up to 100 times on SMTP errors; each runs independently so one failure doesn't block the other
   - Both emails include the `X-MT-Category` header for Mailtrap dashboard grouping
8. If the Anthropic API is unavailable — the classifier catches the error and returns `{ category: "other", urgent: false }` so emails still flow

## Key Files

| File | Purpose |
|------|---------|
| `app/controllers/contacts_controller.rb` | Handles form submission, orchestrates classify → save → route → mail |
| `app/services/contact_classifier.rb` | Calls the Anthropic API and returns a category string |
| `app/services/contact_router.rb` | Maps category to team email address via env vars |
| `app/mailers/contact_mailer.rb` | Sends team notification and auto-reply with `X-MT-Category` header |
| `app/jobs/deliver_mail_job.rb` | Background job that delivers email with retry on SMTP errors |
| `app/models/contact_submission.rb` | Validates and persists every submission |
| `app/views/contact_mailer/` | HTML and plain-text email templates |
| `config/environments/development.rb` | Mailtrap Email Sending SMTP configuration |
| `config/initializers/mailtrap.rb` | Activates the Mailtrap Sending API adapter in production |

## Mailtrap Integration

**Development** uses Mailtrap Email Sending over live SMTP — emails are delivered through your verified sending domain:

```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  user_name: "api",
  password:  ENV["MAILTRAP_API_TOKEN"],
  address:   "live.smtp.mailtrap.io",
  port:      2525,
  authentication: :login
}
```

**Production** uses the Mailtrap Sending API via the official [`mailtrap`](https://github.com/railsware/mailtrap-ruby) gem:

```ruby
# config/initializers/mailtrap.rb
Rails.application.config.action_mailer.delivery_method = :mailtrap
Rails.application.config.action_mailer.mailtrap_settings = {
  api_key: ENV["MAILTRAP_API_TOKEN"]
}
```

The `X-MT-Category` header groups emails by category in the Mailtrap dashboard:

```ruby
prefix  = submission.urgent? ? "[URGENT]" : nil
subject = ["[#{submission.category.capitalize}]", prefix, "New contact from #{submission.name}"].compact.join(" ")

mail(
  to:      team_email,
  subject: subject,
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
- Classifier result (category and urgency) is stored on the submission record
- Spam submissions skip email delivery
- Invalid submissions re-render the form with errors
- Background job enqueues both team notification and auto-reply

## License

MIT License — see [LICENSE](LICENSE) for details.
