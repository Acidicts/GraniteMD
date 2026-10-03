source "https://rubygems.org"

gem "dotenv"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"

# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"

# Use postgre-sql as the database for Active Record and redis for caching
gem "pg"
gem "redis"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator   [https://turbo.hotwired.dev]
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "turbo-rails"
gem "stimulus-rails"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
gem "erb", ">= 6.0.4"

# Image
gem "ruby-vips"
gem "image_processing", "~> 1.2"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", ">= 8.0.6", require: false
  gem "rubocop-rails-omakase", require: false
  gem "erb_lint", require: false

  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "web-console"
  gem "annotaterb"
  gem "rails_live_reload"

  gem "ruby-lsp", ">= 0.18.0", require: false
  gem "ruby-lsp-rails", require: false

  gem "rubocop", require: false
  gem "htmlbeautifier", require: false
end

group :test do
  gem "shoulda-matchers"
  gem "capybara"
  gem "selenium-webdriver"
end

gem "bcrypt", "~> 3.1"
