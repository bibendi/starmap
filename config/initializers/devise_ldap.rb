# Devise LDAP Configuration for Starmap
# This initializer configures Devise to work with LDAP authentication

require 'net/ldap'

# Load LDAP configuration
ldap_config = YAML.load_file(Rails.root.join('config/ldap.yml'))[Rails.env]

# Devise LDAP settings
Devise.setup do |config|
  # LDAP configuration
  config.ldap_logger = true
  config.ldap_create_user = true
  config.ldap_update_user = true
  config.ldap_check_group_membership = false
  config.ldap_check_group_membership_without_admin = false
  config.ldap_check_attributes = false
  config.ldap_use_admin_to_bind = true
  config.ldap_auth_username_builder = proc { |attribute, login, ldap|
    "#{attribute}=#{login},#{ldap_config['base_dn']}"
  }

  # LDAP connection settings
  config.ldap_host = ldap_config['host']
  config.ldap_port = ldap_config['port']
  config.ldap_base_dn = ldap_config['base_dn']
  config.ldap_attribute = ldap_config['attribute']
  config.ldap_admin_user = ldap_config['admin_user']
  config.ldap_admin_password = ldap_config['admin_password']
  config.ldap_ssl = ldap_config['ssl']
  config.ldap_tls = ldap_config['tls']

  # Timeout settings
  config.ldap_timeout = 10
  config.ldap_connect_timeout = 5
  config.ldap_read_timeout = 5

  # Group mappings for role assignment
  config.ldap_group_mappings = {
    'admin' => ldap_config['admin_groups'] || [],
    'unit_lead' => ldap_config['unit_lead_groups'] || [],
    'team_lead' => ldap_config['team_lead_groups'] || [],
    'engineer' => ldap_config['engineer_groups'] || []
  }

  # User attribute mappings
  config.ldap_user_attributes = {
    'email' => ldap_config['email_attr'],
    'first_name' => ldap_config['first_name_attr'],
    'last_name' => ldap_config['last_name_attr'],
    'display_name' => ldap_config['display_name_attr'],
    'department' => ldap_config['department_attr'],
    'position' => ldap_config['position_attr'],
    'phone' => ldap_config['phone_attr'],
    'employee_id' => ldap_config['employee_id_attr']
  }

  # Additional Devise configuration
  config.mailer_sender = ENV['MAIL_FROM_EMAIL'] || 'noreply@company.com'
  config.password_length = 6..128
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.select_company_on_signup = :required
end

# LDAP helper module for User model
module LdapHelper
  extend ActiveSupport::Concern

  included do
    # Add LDAP-specific scopes and methods
    scope :active, -> { where(active: true) }
    scope :by_role, ->(role) { where(role: role) }
    scope :engineers, -> { where(role: 'engineer') }
    scope :team_leads, -> { where(role: 'team_lead') }
    scope :unit_leads, -> { where(role: 'unit_lead') }
    scope :admins, -> { where(role: 'admin') }
    scope :by_team, ->(team_id) { where(team_id: team_id) }
  end

  # Role checking methods
  def engineer?
    role == 'engineer'
  end

  def team_lead?
    role == 'team_lead'
  end

  def unit_lead?
    role == 'unit_lead'
  end

  def admin?
    role == 'admin' || admin?
  end

  # Team leadership check
  def team_lead_of?(team)
    team_lead? && team_id == team.id
  end

  # Unit leadership check (can see all teams in unit)
  def unit_lead_of_unit?(unit)
    unit_lead? # For now, unit leads can see all units
  end

  # LDAP data helpers
  def full_name
    [first_name, last_name].compact.join(' ')
  end

  def display_name_or_full_name
    display_name.presence || full_name
  end

  # LDAP sync status
  def last_ldap_sync_info
    last_ldap_sync_at&.strftime('%d.%m.%Y %H:%M')
  end

  def needs_ldap_sync?
    last_ldap_sync_at.nil? || last_ldap_sync_at < 1.day.ago
  end
end

# Add LdapHelper to User model when it's created
# This will be included in the User model later
