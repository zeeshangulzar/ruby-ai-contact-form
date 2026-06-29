class ContactClassifier
  CATEGORIES = %w[sales support partnership spam other].freeze

  def initialize(name:, email:, message:)
    @name    = name
    @email   = email
    @message = message
  end

  def classify
    client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])

    response = client.messages(
      parameters: {
        model: "claude-3-5-haiku-20241022",
        max_tokens: 10,
        messages: [{ role: "user", content: prompt }]
      }
    )

    category = response.dig("content", 0, "text").to_s.strip.downcase
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
