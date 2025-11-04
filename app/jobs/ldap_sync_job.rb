# LDAP Sync Job for Starmap
# Synchronizes users from LDAP directory to Starmap database
class LdapSyncJob < ApplicationJob
  queue_as :default

  # Retry configuration
  retry_on Net::LDAP::Error, wait: :exponentially_longer, attempts: 3
  retry_on StandardError, wait: :exponentially_longer, attempts: 2

  def perform(force_sync: false)
    Rails.logger.info "Starting LDAP sync job"

    ldap_config = load_ldap_config
    ldap_connection = establish_ldap_connection(ldap_config)

    begin
      # Get all users from LDAP
      ldap_users = fetch_ldap_users(ldap_connection, ldap_config)
      Rails.logger.info "Found #{ldap_users.count} users in LDAP"

      # Process each user
      processed_count = 0
      ldap_users.each do |ldap_user|
        begin
          sync_user(ldap_user, ldap_config)
          processed_count += 1
        rescue => e
          Rails.logger.error "Failed to sync user #{ldap_user[:uid]&.first}: #{e.message}"
        end
      end

      # Clean up users that no longer exist in LDAP
      cleanup_removed_users(ldap_users.map { |u| u[:uid]&.first }.compact, ldap_config)

      Rails.logger.info "LDAP sync completed. Processed #{processed_count} users"

      # Update last sync timestamp
      Rails.cache.write('ldap_last_sync_at', Time.current)

    rescue => e
      Rails.logger.error "LDAP sync failed: #{e.message}"
      raise e
    ensure
      ldap_connection&.disconnect
    end
  end

  private

  def load_ldap_config
    config = YAML.load_file(Rails.root.join('config/ldap.yml'))[Rails.env]
    raise "LDAP configuration not found for #{Rails.env}" unless config

    config.with_indifferent_access
  end

  def establish_ldap_connection(config)
    ldap_config = {
      host: config[:host],
      port: config[:port],
      encryption: config[:ssl] ? :simple_tls : nil,
      auth: {
        method: :simple,
        username: config[:admin_user],
        password: config[:admin_password]
      }
    }

    Net::LDAP.new(ldap_config)
  end

  def fetch_ldap_users(connection, config)
    users = []

    filter = Net::LDAP::Filter.construct(config[:user_filter])
    base_dn = config[:base_dn]

    connection.search(base: base_dn, filter: filter) do |entry|
      user_data = {
        uid: entry[config[:attribute]],
        dn: entry.dn,
        email: entry[config[:email_attr]],
        first_name: entry[config[:first_name_attr]],
        last_name: entry[config[:last_name_attr]],
        display_name: entry[config[:display_name_attr]],
        department: entry[config[:department_attr]],
        position: entry[config[:position_attr]],
        phone: entry[config[:phone_attr]],
        employee_id: entry[config[:employee_id_attr]],
        groups: fetch_user_groups(connection, entry.dn, config)
      }
      users << user_data
    end

    users
  end

  def fetch_user_groups(connection, user_dn, config)
    groups = []
    group_filter = Net::LDAP::Filter.construct(config[:group_filter])

    connection.search(base: config[:group_base], filter: group_filter) do |entry|
      # Check if user is member of this group
      if entry[:member]&.include?(user_dn)
        groups << entry[:cn]&.first
      end
    end

    groups
  end

  def sync_user(ldap_user, config)
    uid = ldap_user[:uid]&.first
    return if uid.blank?

    # Find or create user
    user = User.find_or_initialize_by(ldap_uid: uid)

    # Update user attributes
    user.assign_attributes(
      email: ldap_user[:email]&.first,
      first_name: ldap_user[:first_name]&.first || 'Unknown',
      last_name: ldap_user[:last_name]&.first || 'User',
      display_name: ldap_user[:display_name]&.first,
      department: ldap_user[:department]&.first,
      position: ldap_user[:position]&.first,
      phone: ldap_user[:phone]&.first,
      employee_id: ldap_user[:employee_id]&.first,
      ldap_dn: ldap_user[:dn],
      ldap_data: ldap_user.to_json,
      last_ldap_sync_at: Time.current,
      active: true
    )

    # Determine role based on LDAP groups
    user.role = determine_role_from_groups(ldap_user[:groups], config)

    # Try to assign team based on department or other criteria
    assign_team_to_user(user, ldap_user, config)

    # Save user
    if user.changed?
      user.save!
      Rails.logger.info "Synced user: #{user.email} (#{user.role})"
    end

    user
  end

  def determine_role_from_groups(groups, config)
    return 'admin' if groups&.any? { |g| config[:admin_groups]&.include?(g) }
    return 'unit_lead' if groups&.any? { |g| config[:unit_lead_groups]&.include?(g) }
    return 'team_lead' if groups&.any? { |g| config[:team_lead_groups]&.include?(g) }
    return 'engineer' if groups&.any? { |g| config[:engineer_groups]&.include?(g) }

    'engineer' # Default role
  end

  def assign_team_to_user(user, ldap_user, config)
    # Try to find team by department or other criteria
    department = ldap_user[:department]&.first
    return if department.blank?

    # For now, create team if it doesn't exist
    team = Team.find_or_create_by(name: department) do |t|
      t.description = "Team for #{department} department"
    end

    user.team = team
  end

  def cleanup_removed_users(current_ldap_uids, config)
    # Find users that exist in database but not in LDAP
    stale_users = User.where.not(ldap_uid: nil).where.not(ldap_uid: current_ldap_uids)

    stale_users.each do |user|
      # Mark as inactive instead of deleting
      user.update!(active: false)
      Rails.logger.info "Marked user as inactive: #{user.email}"
    end
  end
end
