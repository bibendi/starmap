source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"

# Authentication and Authorization
gem "devise"
gem "devise_ldap_authenticatable"
gem "pundit"

# Hotwire for interactivity
gem "hotwire-rails"

# Background jobs and caching
gem "solid_queue"
gem "solid_cache"

# Audit and versioning
gem "audited"

# LDAP utilities
gem "net-ldap"

# Email handling
gem "letter_opener", group: :development

# Utilities
gem "annotate", group: :development
gem "brakeman", group: :development

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
end

group :test do
  # Testing framework
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "capybara"
  gem "selenium-webdriver"
  gem "database_cleaner-active_record"
end
