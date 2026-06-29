FactoryBot.define do
  factory :contact_submission do
    name       { "Jane Smith" }
    email      { "jane@example.com" }
    message    { "I'd like to learn more about your pricing plans." }
    category   { "sales" }
    ip_address { "127.0.0.1" }
  end
end
