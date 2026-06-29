source "https://rubygems.org"

ruby "3.3.6"

gem "rails", "~> 7.2.3"
gem "sprockets-rails"
gem "sqlite3", ">= 1.4"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false

gem "anthropic"
gem "mailtrap"
gem "dotenv-rails"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails"
end

group :development do
  gem "web-console"
end

