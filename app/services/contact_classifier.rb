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
      max_tokens: 10,
      messages: [{ role: "user", content: prompt }]
    )

    category = response.content.first.text.to_s.strip.downcase
    CATEGORIES.include?(category) ? category : "other"
  rescue => e
    Rails.logger.error("ContactClassifier error: #{e.message}")
    "other"
  end

  private

  def prompt
    <<~PROMPT
      Classify this contact form submission into exactly one of these categories:
      sales, support, partnership, spam, other

      Respond with only the single category word, nothing else.

      Name: #{@name}
      Email: #{@email}
      Message: #{@message}
    PROMPT
  end
end
