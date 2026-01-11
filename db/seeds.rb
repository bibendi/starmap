# Seeds file for Starmap application
# Creates test users, teams, technologies, and sample data

puts "Creating units..."

engineering_unit = Unit.find_or_create_by!(name: 'Engineering') do |unit|
  unit.description = 'Main engineering unit'
end

puts "Created unit: #{engineering_unit.name}"
puts ""

puts "Creating teams..."

# Create teams
teams = {
  backend: Team.find_or_create_by!(name: 'Backend Team') do |team|
    team.description = 'Backend development team'
    team.unit = engineering_unit
  end,
  frontend: Team.find_or_create_by!(name: 'Frontend Team') do |team|
    team.description = 'Frontend development team'
    team.unit = engineering_unit
  end,
  devops: Team.find_or_create_by!(name: 'DevOps Team') do |team|
    team.description = 'DevOps and infrastructure team'
    team.unit = engineering_unit
  end,
  mobile: Team.find_or_create_by!(name: 'Mobile Team') do |team|
    team.description = 'Mobile development team'
    team.unit = engineering_unit
  end
}

puts "Creating technologies..."

# Create technologies with different criticality levels
technologies = {
  ruby_on_rails: Technology.find_or_create_by!(name: 'Ruby on Rails') do |tech|
    tech.description = 'Web application framework'
    tech.criticality = 'high'
    tech.category = 'backend'
  end,
  postgresql: Technology.find_or_create_by!(name: 'PostgreSQL') do |tech|
    tech.description = 'Relational database'
    tech.criticality = 'high'
    tech.category = 'database'
  end,
  react: Technology.find_or_create_by!(name: 'React') do |tech|
    tech.description = 'JavaScript library for building user interfaces'
    tech.criticality = 'high'
    tech.category = 'frontend'
  end,
  docker: Technology.find_or_create_by!(name: 'Docker') do |tech|
    tech.description = 'Containerization platform'
    tech.criticality = 'high'
    tech.category = 'devops'
  end,
  kubernetes: Technology.find_or_create_by!(name: 'Kubernetes') do |tech|
    tech.description = 'Container orchestration platform'
    tech.criticality = 'high'
    tech.category = 'devops'
  end,
  aws: Technology.find_or_create_by!(name: 'AWS') do |tech|
    tech.description = 'Amazon Web Services cloud platform'
    tech.criticality = 'high'
    tech.category = 'cloud'
  end,
  javascript: Technology.find_or_create_by!(name: 'JavaScript') do |tech|
    tech.description = 'Programming language for web development'
    tech.criticality = 'high'
    tech.category = 'frontend'
  end,
  typescript: Technology.find_or_create_by!(name: 'TypeScript') do |tech|
    tech.description = 'Typed superset of JavaScript'
    tech.criticality = 'normal'
    tech.category = 'frontend'
  end,
  nodejs: Technology.find_or_create_by!(name: 'Node.js') do |tech|
    tech.description = 'JavaScript runtime environment'
    tech.criticality = 'normal'
    tech.category = 'backend'
  end,
  redis: Technology.find_or_create_by!(name: 'Redis') do |tech|
    tech.description = 'In-memory data structure store'
    tech.criticality = 'normal'
    tech.category = 'database'
  end,
  graphql: Technology.find_or_create_by!(name: 'GraphQL') do |tech|
    tech.description = 'Query language for APIs'
    tech.criticality = 'normal'
    tech.category = 'backend'
  end,
  terraform: Technology.find_or_create_by!(name: 'Terraform') do |tech|
    tech.description = 'Infrastructure as code tool'
    tech.criticality = 'normal'
    tech.category = 'devops'
  end,
  vuejs: Technology.find_or_create_by!(name: 'Vue.js') do |tech|
    tech.description = 'Progressive JavaScript framework'
    tech.criticality = 'low'
    tech.category = 'frontend'
  end,
  angular: Technology.find_or_create_by!(name: 'Angular') do |tech|
    tech.description = 'TypeScript-based web application framework'
    tech.criticality = 'low'
    tech.category = 'frontend'
  end
}

puts "Creating quarters..."

# Create current and previous quarters
current_quarter = Quarter.find_or_create_by!(
  year: 2024,
  quarter_number: 4
) do |quarter|
  quarter.name = 'Q4 2024'
  quarter.start_date = Date.new(2024, 10, 1)
  quarter.end_date = Date.new(2024, 12, 31)
  quarter.status = 'active'
  quarter.description = 'Fourth quarter 2024'
  quarter.is_current = true
end

previous_quarter = Quarter.find_or_create_by!(
  year: 2024,
  quarter_number: 3
) do |quarter|
  quarter.name = 'Q3 2024'
  quarter.start_date = Date.new(2024, 7, 1)
  quarter.end_date = Date.new(2024, 9, 30)
  quarter.status = 'closed'
  quarter.description = 'Third quarter 2024'
  quarter.is_current = false
  quarter.previous_quarter_id = nil  # No previous quarter
end

# Link quarters
current_quarter.update!(previous_quarter_id: previous_quarter.id)

puts "Creating test users..."

# Create admin user
admin_user = User.find_or_create_by!(email: 'admin@company.com') do |user|
  user.first_name = 'System'
  user.last_name = 'Administrator'
  user.display_name = 'System Administrator'
  user.role = 'admin'
  user.employee_id = 'EMP001'
  user.department = 'IT'
  user.position = 'System Administrator'
  user.phone = '+7 (999) 123-45-67'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.active = true
  user.team_id = nil
end

# Create unit lead
unit_lead_user = User.find_or_create_by!(email: 'unit.lead@company.com') do |user|
  user.first_name = 'Alex'
  user.last_name = 'UnitLead'
  user.display_name = 'Alex UnitLead'
  user.role = 'unit_lead'
  user.employee_id = 'EMP002'
  user.department = 'Engineering'
  user.position = 'Unit Lead'
  user.phone = '+7 (999) 123-45-68'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.active = true
  user.team_id = nil
end

# Set unit lead for unit
engineering_unit.update!(unit_lead_id: unit_lead_user.id)

# Create team leads
backend_team_lead = User.find_or_create_by!(email: 'backend.lead@company.com') do |user|
  user.first_name = 'Bob'
  user.last_name = 'BackendLead'
  user.display_name = 'Bob BackendLead'
  user.role = 'team_lead'
  user.team_id = teams[:backend].id
  user.employee_id = 'EMP003'
  user.department = 'Engineering'
  user.position = 'Senior Backend Developer'
  user.phone = '+7 (999) 123-45-69'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.active = true
end

frontend_team_lead = User.find_or_create_by!(email: 'frontend.lead@company.com') do |user|
  user.first_name = 'Carol'
  user.last_name = 'FrontendLead'
  user.display_name = 'Carol FrontendLead'
  user.role = 'team_lead'
  user.team_id = teams[:frontend].id
  user.employee_id = 'EMP004'
  user.department = 'Engineering'
  user.position = 'Senior Frontend Developer'
  user.phone = '+7 (999) 123-45-70'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.active = true
end

devops_team_lead = User.find_or_create_by!(email: 'devops.lead@company.com') do |user|
  user.first_name = 'David'
  user.last_name = 'DevOpsLead'
  user.display_name = 'David DevOpsLead'
  user.role = 'team_lead'
  user.team_id = teams[:devops].id
  user.employee_id = 'EMP005'
  user.department = 'Engineering'
  user.position = 'DevOps Engineer'
  user.phone = '+7 (999) 123-45-71'
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.active = true
end

# Set team leads
teams[:backend].update!(team_lead_id: backend_team_lead.id)
teams[:frontend].update!(team_lead_id: frontend_team_lead.id)
teams[:devops].update!(team_lead_id: devops_team_lead.id)

# Create engineers
engineers = [
  {
    email: 'john.doe@company.com',
    first_name: 'John',
    last_name: 'Doe',
    display_name: 'John Doe',
    role: 'engineer',
    team_id: teams[:backend].id,
    employee_id: 'EMP006',
    department: 'Engineering',
    position: 'Backend Developer',
    phone: '+7 (999) 123-45-72'
  },
  {
    email: 'jane.smith@company.com',
    first_name: 'Jane',
    last_name: 'Smith',
    display_name: 'Jane Smith',
    role: 'engineer',
    team_id: teams[:frontend].id,
    employee_id: 'EMP007',
    department: 'Engineering',
    position: 'Frontend Developer',
    phone: '+7 (999) 123-45-73'
  },
  {
    email: 'mike.wilson@company.com',
    first_name: 'Mike',
    last_name: 'Wilson',
    display_name: 'Mike Wilson',
    role: 'engineer',
    team_id: teams[:devops].id,
    employee_id: 'EMP008',
    department: 'Engineering',
    position: 'DevOps Engineer',
    phone: '+7 (999) 123-45-74'
  },
  {
    email: 'sarah.brown@company.com',
    first_name: 'Sarah',
    last_name: 'Brown',
    display_name: 'Sarah Brown',
    role: 'engineer',
    team_id: teams[:backend].id,
    employee_id: 'EMP009',
    department: 'Engineering',
    position: 'Backend Developer',
    phone: '+7 (999) 123-45-75'
  },
  {
    email: 'tom.johnson@company.com',
    first_name: 'Tom',
    last_name: 'Johnson',
    display_name: 'Tom Johnson',
    role: 'engineer',
    team_id: teams[:frontend].id,
    employee_id: 'EMP010',
    department: 'Engineering',
    position: 'Frontend Developer',
    phone: '+7 (999) 123-45-76'
  },
  {
    email: 'lisa.davis@company.com',
    first_name: 'Lisa',
    last_name: 'Davis',
    display_name: 'Lisa Davis',
    role: 'engineer',
    team_id: teams[:mobile].id,
    employee_id: 'EMP011',
    department: 'Engineering',
    position: 'Mobile Developer',
    phone: '+7 (999) 123-45-77'
  }
]

engineers.each do |engineer_data|
  User.find_or_create_by!(email: engineer_data[:email]) do |user|
    user.assign_attributes(engineer_data)
    user.password = 'password123'
  user.password_confirmation = 'password123'
    user.active = true
  end
end

puts "Creating sample skill ratings..."

# Create sample skill ratings for current quarter

# Define skill levels for each user (0-3 scale)
user_skills = {
  admin_user.id => {
    technologies[:ruby_on_rails].id => 3,
    technologies[:postgresql].id => 3,
    technologies[:docker].id => 3,
    technologies[:aws].id => 3
  },
  unit_lead_user.id => {
    technologies[:ruby_on_rails].id => 3,
    technologies[:react].id => 2,
    technologies[:postgresql].id => 3,
    technologies[:docker].id => 2
  },
  backend_team_lead.id => {
    technologies[:ruby_on_rails].id => 3,
    technologies[:postgresql].id => 3,
    technologies[:redis].id => 2,
    technologies[:graphql].id => 2,
    technologies[:nodejs].id => 2
  },
  frontend_team_lead.id => {
    technologies[:react].id => 3,
    technologies[:javascript].id => 3,
    technologies[:typescript].id => 3,
    technologies[:vuejs].id => 2,
    technologies[:angular].id => 1
  },
  devops_team_lead.id => {
    technologies[:docker].id => 3,
    technologies[:kubernetes].id => 3,
    technologies[:aws].id => 3,
    technologies[:terraform].id => 2,
    technologies[:postgresql].id => 1
  }
}

# Add skills for engineers
engineer_emails = ['john.doe@company.com', 'jane.smith@company.com', 'mike.wilson@company.com',
                   'sarah.brown@company.com', 'tom.johnson@company.com', 'lisa.davis@company.com']

engineer_skills = {
  'john.doe@company.com' => {
    technologies[:ruby_on_rails].id => 2,
    technologies[:postgresql].id => 2,
    technologies[:redis].id => 1,
    technologies[:graphql].id => 1
  },
  'jane.smith@company.com' => {
    technologies[:react].id => 2,
    technologies[:javascript].id => 2,
    technologies[:typescript].id => 1,
    technologies[:vuejs].id => 1
  },
  'mike.wilson@company.com' => {
    technologies[:docker].id => 2,
    technologies[:kubernetes].id => 1,
    technologies[:aws].id => 2,
    technologies[:terraform].id => 1
  },
  'sarah.brown@company.com' => {
    technologies[:ruby_on_rails].id => 1,
    technologies[:postgresql].id => 2,
    technologies[:nodejs].id => 1,
    technologies[:graphql].id => 1
  },
  'tom.johnson@company.com' => {
    technologies[:react].id => 1,
    technologies[:javascript].id => 2,
    technologies[:typescript].id => 2,
    technologies[:angular].id => 1
  },
  'lisa.davis@company.com' => {
    technologies[:react].id => 2,
    technologies[:javascript].id => 2,
    technologies[:nodejs].id => 1,
    technologies[:aws].id => 1
  }
}

# Create skill ratings
user_skills.each do |user_id, skills|
  skills.each do |tech_id, rating_level|
    SkillRating.find_or_create_by!(
      user_id: user_id,
      technology_id: tech_id,
      quarter_id: current_quarter.id
    ) do |rating|
      rating.rating = rating_level
      rating.status = 'approved'
      rating.approved_at = Time.current
      rating.approved_by_id = unit_lead_user.id
      rating.locked = true
    end
  end
end

engineer_skills.each do |email, skills|
  user = User.find_by(email: email)
  next unless user

  skills.each do |tech_id, rating_level|
    SkillRating.find_or_create_by!(
      user_id: user.id,
      technology_id: tech_id,
      quarter_id: current_quarter.id
    ) do |rating|
      rating.rating = rating_level
      rating.status = 'draft'
      rating.locked = false
    end
  end
end

puts "Creating sample action plans..."

# Create sample action plans
ActionPlan.find_or_create_by!(
  title: 'Improve React skills',
  description: 'Complete React advanced course and build 2 projects',
  user_id: User.find_by(email: 'john.doe@company.com')&.id,
  technology_id: technologies[:react].id,
  quarter_id: current_quarter.id,
  status: 'in_progress',
  priority: 'high',
  created_by_id: backend_team_lead.id
)

ActionPlan.find_or_create_by!(
  title: 'Learn Docker containerization',
  description: 'Complete Docker certification and implement in current project',
  user_id: User.find_by(email: 'sarah.brown@company.com')&.id,
  technology_id: technologies[:docker].id,
  quarter_id: current_quarter.id,
  status: 'active',
  priority: 'medium',
  created_by_id: backend_team_lead.id
)

ActionPlan.find_or_create_by!(
  title: 'AWS certification preparation',
  description: 'Prepare and pass AWS Solutions Architect certification',
  user_id: User.find_by(email: 'lisa.davis@company.com')&.id,
  technology_id: technologies[:aws].id,
  quarter_id: current_quarter.id,
  status: 'in_progress',
  priority: 'high',
  created_by_id: unit_lead_user.id
)

puts "Seeding completed successfully!"

puts "\n=== Test Users Created ==="
puts "Admin: admin@company.com"
puts "Unit Lead: unit.lead@company.com"
puts "Backend Team Lead: backend.lead@company.com"
puts "Frontend Team Lead: frontend.lead@company.com"
puts "DevOps Team Lead: devops.lead@company.com"
puts "Engineers: john.doe@company.com, jane.smith@company.com, mike.wilson@company.com, sarah.brown@company.com, tom.johnson@company.com, lisa.davis@company.com"
puts "\nAll users have password: password123"
