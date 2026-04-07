# Devise configuration for Starmap
require "devise"

# Use database authentication
Devise.setup do |config|
  # ==> Configuration for any authentication mechanism
  # Configure which e-mail addresses are monitored and used to send notifications on recovery
  config.mailer_sender = "please-change-me@example.com"

  # Configure the class responsible to send e-mails.
  # config.mailer = 'Devise::Mailer'

  # Configure the parent class responsible to send e-mails.
  # config.parent_mailer = 'ActionMailer::Base'

  # ==> ORM configuration
  # Active Record requires the devise_orm gem
  require "devise/orm/active_record"

  # ==> Configuration for :database_authenticatable
  # For bcrypt, this is the cost for hashing the password and is offered as configuration.
  # As stated in the article comment above, this cost should be at least 10.
  # Changing it to 15 would be the same of for BCrypt 2.x.
  config.password_length = 6..128

  # Sessions
  config.sign_out_via = :delete

  # Timeouts
  config.timeout_in = 30.minutes

  if Rails.env.test?
    config.stretches = 1
  end
end
