class ContactClassifier
  CATEGORIES = %w[sales support partnership spam other].freeze

  def initialize(name:, email:, message:)
    @name    = name
    @email   = email
    @message = message
  end

  def classify
    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])

    response = client.messages.create(
      model: "claude-haiku-4-5-20251001",
      max_tokens: 20,
      messages: [{ role: "user", content: prompt }]
    )

    parse(response.content.first.text.to_s.strip.downcase)
  rescue => e
    Rails.logger.error("ContactClassifier error: #{e.message}")
    { category: "other", urgent: false }
  end

  private

  def parse(text)
    parts    = text.split
    category = CATEGORIES.include?(parts[0]) ? parts[0] : "other"
    urgent   = parts[1] == "urgent"
    { category: category, urgent: urgent }
  end

  def prompt
    <<~PROMPT
      Classify this contact form submission. Respond with exactly two words:
      1. Category: sales, support, partnership, spam, or other
      2. Urgency: urgent or normal

      Example responses: "sales urgent" or "support normal"

      Name: #{@name}
      Email: #{@email}
      Message: #{@message}
    PROMPT
  end
end
