namespace :admin do
  desc "Create initial admin user. Usage: rails admin:create['admin@example.com']"
  task :create, [:email] => :environment do |_t, args|
    abort "Error: Email is required. Usage: rails 'admin:create['admin@example.com']'" if args[:email].blank?

    if User.exists?
      abort "Error: Users already exist in the database. This task is only for initial setup."
    end

    email = args[:email].strip.downcase
    password = SecureRandom.alphanumeric(16)

    User.create!(
      email: email,
      first_name: "Admin",
      last_name: "Admin",
      role: :admin,
      password: password,
      active: true,
      confirmed_at: Time.current
    )

    puts "Admin user created successfully!"
    puts "  Email:    #{email}"
    puts "  Password: #{password}"
  end
end
