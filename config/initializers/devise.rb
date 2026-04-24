# Devise configuration for Starmap
require "devise"
require "warden/bearer_token_strategy"

Devise.setup do |config|
  config.mailer_sender = "please-change-me@example.com"

  require "devise/orm/active_record"

  config.password_length = 6..128

  config.sign_out_via = :delete

  config.timeout_in = 30.minutes

  config.warden do |manager|
    manager.default_strategies(scope: :user).unshift :bearer_token
  end

  if Rails.env.test?
    config.stretches = 1
  end
end
