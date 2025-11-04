# Devise configuration for Starmap
require 'devise'

# Use LDAP for authentication
Devise.setup do |config|
  # ==> Configuration for any authentication mechanism
  # Configure which e-mail addresses are monitored and used to send notifications on recovery
  config.mailer_sender = 'please-change-me@example.com'

  # Configure the class responsible to send e-mails.
  # config.mailer = 'Devise::Mailer'

  # Configure the parent class responsible to send e-mails.
  # config.parent_mailer = 'ActionMailer::Base'

  # ==> ORM configuration
  # Active Record requires the devise_orm gem
  require 'devise/orm/active_record'

  # ==> Configuration for :database_authenticatable
  # For bcrypt, this is the cost for hashing the password and is offered as configuration.
  # As stated in the article comment above, this cost should be at least 10.
  # Changing it to 15 would be the same as for BCrypt 2.x.
  config.password_length = 6..128

  # Sessions
  config.sign_out_via = :delete

  # Timeouts
  config.timeout_in = 30.minutes
end

# Configure LDAP for authentication
if defined?(DeviseLdapAdapter)
  DeviseLdapAdapter.setup do |config|
    # LDAP configuration
    config.logger = true
    config.create_user = true
    config.check_group_membership = false
    config.check_group_membership_without_admin = false
    config.check_attributes = false
    config.use_admin_to_bind = true

    # Load configuration from ldap.yml
    begin
      ldap_config = YAML.load_file(Rails.root.join('config/ldap.yml'))[Rails.env]
      config.host = ldap_config['host'] || 'ldap.company.com'
      config.port = ldap_config['port'] || 389
      config.base = ldap_config['base_dn'] || 'dc=company,dc=com'
      config.attribute = ldap_config['attribute'] || 'uid'
      config.admin_user = ldap_config['admin_user'] || 'cn=admin,dc=company,dc=com'
      config.admin_password = ldap_config['admin_password'] || 'admin_password'
    rescue Errno::ENOENT
      # Use defaults if config file doesn't exist
      config.host = 'ldap.company.com'
      config.port = 389
      config.base = 'dc=company,dc=com'
      config.attribute = 'uid'
    end
  end
end
