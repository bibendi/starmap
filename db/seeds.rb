# Seeds file for Starmap application
# Creates test users, teams, technologies, and sample data

Rails.logger.debug "Creating units..."

engineering_unit = Unit.find_or_create_by!(name: "Engineering") do |unit|
  unit.description = "Main engineering unit"
end

Rails.logger.debug { "Created unit: #{engineering_unit.name}" }
Rails.logger.debug ""

Rails.logger.debug "Creating teams..."

# Create teams
teams = {
  backend: Team.find_or_create_by!(name: "Backend Team") do |team|
    team.description = "Backend development team"
    team.unit = engineering_unit
  end,
  frontend: Team.find_or_create_by!(name: "Frontend Team") do |team|
    team.description = "Frontend development team"
    team.unit = engineering_unit
  end,
  devops: Team.find_or_create_by!(name: "DevOps Team") do |team|
    team.description = "DevOps and infrastructure team"
    team.unit = engineering_unit
  end,
  mobile: Team.find_or_create_by!(name: "Mobile Team") do |team|
    team.description = "Mobile development team"
    team.unit = engineering_unit
  end
}

Rails.logger.debug "Creating technologies..."

Rails.logger.debug "Creating categories..."

categories = %w[backend frontend database devops cloud].map do |name|
  Category.find_or_create_by!(name: name)
end

category_map = categories.index_by(&:name)

# Create technologies with different criticality levels
technologies = {
  ruby_on_rails: Technology.find_or_create_by!(name: "Ruby on Rails") do |tech|
    tech.description = "Web application framework"
    tech.criticality = "high"
    tech.category = category_map["backend"]
  end,
  postgresql: Technology.find_or_create_by!(name: "PostgreSQL") do |tech|
    tech.description = "Relational database"
    tech.criticality = "high"
    tech.category = category_map["database"]
  end,
  react: Technology.find_or_create_by!(name: "React") do |tech|
    tech.description = "JavaScript library for building user interfaces"
    tech.criticality = "high"
    tech.category = category_map["frontend"]
  end,
  docker: Technology.find_or_create_by!(name: "Docker") do |tech|
    tech.description = "Containerization platform"
    tech.criticality = "high"
    tech.category = category_map["devops"]
  end,
  kubernetes: Technology.find_or_create_by!(name: "Kubernetes") do |tech|
    tech.description = "Container orchestration platform"
    tech.criticality = "high"
    tech.category = category_map["devops"]
  end,
  aws: Technology.find_or_create_by!(name: "AWS") do |tech|
    tech.description = "Amazon Web Services cloud platform"
    tech.criticality = "high"
    tech.category = category_map["cloud"]
  end,
  javascript: Technology.find_or_create_by!(name: "JavaScript") do |tech|
    tech.description = "Programming language for web development"
    tech.criticality = "high"
    tech.category = category_map["frontend"]
  end,
  typescript: Technology.find_or_create_by!(name: "TypeScript") do |tech|
    tech.description = "Typed superset of JavaScript"
    tech.criticality = "normal"
    tech.category = category_map["frontend"]
  end,
  nodejs: Technology.find_or_create_by!(name: "Node.js") do |tech|
    tech.description = "JavaScript runtime environment"
    tech.criticality = "normal"
    tech.category = category_map["backend"]
  end,
  redis: Technology.find_or_create_by!(name: "Redis") do |tech|
    tech.description = "In-memory data structure store"
    tech.criticality = "normal"
    tech.category = category_map["database"]
  end,
  graphql: Technology.find_or_create_by!(name: "GraphQL") do |tech|
    tech.description = "Query language for APIs"
    tech.criticality = "normal"
    tech.category = category_map["backend"]
  end,
  terraform: Technology.find_or_create_by!(name: "Terraform") do |tech|
    tech.description = "Infrastructure as code tool"
    tech.criticality = "normal"
    tech.category = category_map["devops"]
  end,
  vuejs: Technology.find_or_create_by!(name: "Vue.js") do |tech|
    tech.description = "Progressive JavaScript framework"
    tech.criticality = "low"
    tech.category = category_map["frontend"]
  end,
  angular: Technology.find_or_create_by!(name: "Angular") do |tech|
    tech.description = "TypeScript-based web application framework"
    tech.criticality = "low"
    tech.category = category_map["frontend"]
  end
}

Rails.logger.debug "Creating team technology settings..."

# Helper method to determine target_experts based on criticality
def target_experts_for_criticality(criticality)
  case criticality
  when "high" then 3
  when "normal" then 2
  when "low" then 1
  else 2
  end
end

# Create team_technology settings for each team
team_settings = {
  teams[:backend] => [
    {tech: technologies[:ruby_on_rails], criticality: "high"},
    {tech: technologies[:postgresql], criticality: "high"},
    {tech: technologies[:redis], criticality: "normal"},
    {tech: technologies[:graphql], criticality: "normal"},
    {tech: technologies[:nodejs], criticality: "normal"}
  ],
  teams[:frontend] => [
    {tech: technologies[:react], criticality: "high"},
    {tech: technologies[:javascript], criticality: "high"},
    {tech: technologies[:typescript], criticality: "normal"},
    {tech: technologies[:vuejs], criticality: "low"},
    {tech: technologies[:angular], criticality: "low"}
  ],
  teams[:devops] => [
    {tech: technologies[:docker], criticality: "high"},
    {tech: technologies[:kubernetes], criticality: "high"},
    {tech: technologies[:aws], criticality: "high"},
    {tech: technologies[:terraform], criticality: "normal"},
    {tech: technologies[:postgresql], criticality: "normal"}
  ],
  teams[:mobile] => [
    {tech: technologies[:react], criticality: "high"},
    {tech: technologies[:javascript], criticality: "high"},
    {tech: technologies[:nodejs], criticality: "normal"},
    {tech: technologies[:aws], criticality: "normal"}
  ]
}

team_settings.each do |team, settings|
  settings.each do |setting|
    TeamTechnology.find_or_create_by!(
      team_id: team.id,
      technology_id: setting[:tech].id
    ) do |tt|
      tt.criticality = setting[:criticality]
      tt.target_experts = target_experts_for_criticality(setting[:criticality])
    end
  end
end

Rails.logger.debug "Creating quarters..."

now = Date.current
current_q_num = ((now.month - 1) / 3) + 1
current_year = now.year

prev_q_num = current_q_num - 1
prev_year = current_year
if prev_q_num.zero?
  prev_q_num = 4
  prev_year = current_year - 1
end

quarter_start_month = lambda { |q_num| (q_num - 1) * 3 + 1 }
quarter_end_month = lambda { |q_num| q_num * 3 }

current_start = Date.new(current_year, quarter_start_month.call(current_q_num), 1)
current_end = Date.new(current_year, quarter_end_month.call(current_q_num), -1)
prev_start = Date.new(prev_year, quarter_start_month.call(prev_q_num), 1)
prev_end = Date.new(prev_year, quarter_end_month.call(prev_q_num), -1)

current_quarter = Quarter.find_or_create_by!(
  year: current_year,
  quarter_number: current_q_num
) do |quarter|
  quarter.name = "Q#{current_q_num} #{current_year}"
  quarter.start_date = current_start
  quarter.end_date = current_end
  quarter.status = "active"
  quarter.description = "Quarter #{current_q_num} #{current_year}"
  quarter.is_current = true
end

previous_quarter = Quarter.find_or_create_by!(
  year: prev_year,
  quarter_number: prev_q_num
) do |quarter|
  quarter.name = "Q#{prev_q_num} #{prev_year}"
  quarter.start_date = prev_start
  quarter.end_date = prev_end
  quarter.status = "closed"
  quarter.description = "Quarter #{prev_q_num} #{prev_year}"
  quarter.is_current = false
  quarter.previous_quarter_id = nil
end

current_quarter.update!(previous_quarter_id: previous_quarter.id)

Rails.logger.debug "Creating test users..."

# Create admin user
User.find_or_create_by!(email: "admin@company.com") do |user|
  user.first_name = "System"
  user.last_name = "Administrator"
  user.display_name = "System Administrator"
  user.role = "admin"
  user.employee_id = "EMP001"
  user.department = "IT"
  user.position = "System Administrator"
  user.phone = "+7 (999) 123-45-67"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.active = true
  user.team_id = nil
  user.confirmed_at = Time.current
end

# Create unit lead
unit_lead_user = User.find_or_create_by!(email: "unit.lead@company.com") do |user|
  user.first_name = "Alex"
  user.last_name = "UnitLead"
  user.display_name = "Alex UnitLead"
  user.role = "unit_lead"
  user.employee_id = "EMP002"
  user.department = "Engineering"
  user.position = "Unit Lead"
  user.phone = "+7 (999) 123-45-68"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.active = true
  user.team_id = nil
  user.confirmed_at = Time.current
end

# Set unit lead for unit
engineering_unit.update!(unit_lead_id: unit_lead_user.id)

# Create team leads
backend_team_lead = User.find_or_create_by!(email: "backend.lead@company.com") do |user|
  user.first_name = "Bob"
  user.last_name = "BackendLead"
  user.display_name = "Bob BackendLead"
  user.role = "team_lead"
  user.team_id = teams[:backend].id
  user.employee_id = "EMP003"
  user.department = "Engineering"
  user.position = "Senior Backend Developer"
  user.phone = "+7 (999) 123-45-69"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.active = true
  user.confirmed_at = Time.current
end

frontend_team_lead = User.find_or_create_by!(email: "frontend.lead@company.com") do |user|
  user.first_name = "Carol"
  user.last_name = "FrontendLead"
  user.display_name = "Carol FrontendLead"
  user.role = "team_lead"
  user.team_id = teams[:frontend].id
  user.employee_id = "EMP004"
  user.department = "Engineering"
  user.position = "Senior Frontend Developer"
  user.phone = "+7 (999) 123-45-70"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.active = true
  user.confirmed_at = Time.current
end

devops_team_lead = User.find_or_create_by!(email: "devops.lead@company.com") do |user|
  user.first_name = "David"
  user.last_name = "DevOpsLead"
  user.display_name = "David DevOpsLead"
  user.role = "team_lead"
  user.team_id = teams[:devops].id
  user.employee_id = "EMP005"
  user.department = "Engineering"
  user.position = "DevOps Engineer"
  user.phone = "+7 (999) 123-45-71"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.active = true
  user.confirmed_at = Time.current
end

# Set team leads
teams[:backend].update!(team_lead_id: backend_team_lead.id)
teams[:frontend].update!(team_lead_id: frontend_team_lead.id)
teams[:devops].update!(team_lead_id: devops_team_lead.id)

# Create engineers
engineers = [
  {
    email: "john.doe@company.com",
    first_name: "John",
    last_name: "Doe",
    display_name: "John Doe",
    role: "engineer",
    team_id: teams[:backend].id,
    employee_id: "EMP006",
    department: "Engineering",
    position: "Backend Developer",
    phone: "+7 (999) 123-45-72"
  },
  {
    email: "jane.smith@company.com",
    first_name: "Jane",
    last_name: "Smith",
    display_name: "Jane Smith",
    role: "engineer",
    team_id: teams[:frontend].id,
    employee_id: "EMP007",
    department: "Engineering",
    position: "Frontend Developer",
    phone: "+7 (999) 123-45-73"
  },
  {
    email: "mike.wilson@company.com",
    first_name: "Mike",
    last_name: "Wilson",
    display_name: "Mike Wilson",
    role: "engineer",
    team_id: teams[:devops].id,
    employee_id: "EMP008",
    department: "Engineering",
    position: "DevOps Engineer",
    phone: "+7 (999) 123-45-74"
  },
  {
    email: "sarah.brown@company.com",
    first_name: "Sarah",
    last_name: "Brown",
    display_name: "Sarah Brown",
    role: "engineer",
    team_id: teams[:backend].id,
    employee_id: "EMP009",
    department: "Engineering",
    position: "Backend Developer",
    phone: "+7 (999) 123-45-75"
  },
  {
    email: "tom.johnson@company.com",
    first_name: "Tom",
    last_name: "Johnson",
    display_name: "Tom Johnson",
    role: "engineer",
    team_id: teams[:frontend].id,
    employee_id: "EMP010",
    department: "Engineering",
    position: "Frontend Developer",
    phone: "+7 (999) 123-45-76"
  },
  {
    email: "lisa.davis@company.com",
    first_name: "Lisa",
    last_name: "Davis",
    display_name: "Lisa Davis",
    role: "engineer",
    team_id: teams[:mobile].id,
    employee_id: "EMP011",
    department: "Engineering",
    position: "Mobile Developer",
    phone: "+7 (999) 123-45-77"
  },
  {
    email: "james.miller@company.com",
    first_name: "James",
    last_name: "Miller",
    display_name: "James Miller",
    role: "engineer",
    team_id: teams[:backend].id,
    employee_id: "EMP012",
    department: "Engineering",
    position: "Backend Developer",
    phone: "+7 (999) 123-45-78"
  },
  {
    email: "emma.taylor@company.com",
    first_name: "Emma",
    last_name: "Taylor",
    display_name: "Emma Taylor",
    role: "engineer",
    team_id: teams[:backend].id,
    employee_id: "EMP013",
    department: "Engineering",
    position: "Senior Backend Developer",
    phone: "+7 (999) 123-45-79"
  }
]

engineers.each do |engineer_data|
  User.find_or_create_by!(email: engineer_data[:email]) do |user|
    user.assign_attributes(engineer_data)
    user.password = "password123"
    user.password_confirmation = "password123"
    user.active = true
    user.confirmed_at = Time.current
  end
end

Rails.logger.debug "Creating sample skill ratings..."

# Create sample skill ratings for current quarter

# Define skill levels for each user (0-3 scale)
# Admin and unit lead are excluded as they don't have team_id
user_skills = {
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

engineer_skills = {
  "john.doe@company.com" => {
    technologies[:ruby_on_rails].id => 2,
    technologies[:postgresql].id => 2,
    technologies[:redis].id => 1,
    technologies[:graphql].id => 1
  },
  "jane.smith@company.com" => {
    technologies[:react].id => 2,
    technologies[:javascript].id => 2,
    technologies[:typescript].id => 1,
    technologies[:vuejs].id => 1
  },
  "mike.wilson@company.com" => {
    technologies[:docker].id => 2,
    technologies[:kubernetes].id => 1,
    technologies[:aws].id => 2,
    technologies[:terraform].id => 1
  },
  "sarah.brown@company.com" => {
    technologies[:ruby_on_rails].id => 1,
    technologies[:postgresql].id => 2,
    technologies[:nodejs].id => 1,
    technologies[:graphql].id => 1
  },
  "tom.johnson@company.com" => {
    technologies[:react].id => 1,
    technologies[:javascript].id => 2,
    technologies[:typescript].id => 2,
    technologies[:angular].id => 1
  },
  "lisa.davis@company.com" => {
    technologies[:react].id => 2,
    technologies[:javascript].id => 2,
    technologies[:nodejs].id => 1,
    technologies[:aws].id => 1
  },
  "james.miller@company.com" => {
    technologies[:ruby_on_rails].id => 2,
    technologies[:postgresql].id => 1,
    technologies[:redis].id => 1,
    technologies[:nodejs].id => 1
  },
  "emma.taylor@company.com" => {
    technologies[:ruby_on_rails].id => 3,
    technologies[:postgresql].id => 3,
    technologies[:redis].id => 2,
    technologies[:graphql].id => 2
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
      rating.status = "approved"
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
      rating.team_id = user.team_id
      rating.rating = rating_level
      rating.status = "draft"
      rating.locked = false
    end
  end
end

# Create skill ratings for previous quarter (Q3) to show dynamics
Rails.logger.debug "Creating previous quarter skill ratings for dynamics..."

previous_user_skills = {
  backend_team_lead.id => {
    technologies[:ruby_on_rails].id => 2,
    technologies[:postgresql].id => 3,
    technologies[:redis].id => 2,
    technologies[:graphql].id => 1,
    technologies[:nodejs].id => 2
  },
  frontend_team_lead.id => {
    technologies[:react].id => 3,
    technologies[:javascript].id => 2,
    technologies[:typescript].id => 2,
    technologies[:vuejs].id => 2,
    technologies[:angular].id => 0
  },
  devops_team_lead.id => {
    technologies[:docker].id => 2,
    technologies[:kubernetes].id => 2,
    technologies[:aws].id => 3,
    technologies[:terraform].id => 1,
    technologies[:postgresql].id => 1
  }
}

previous_engineer_skills = {
  "john.doe@company.com" => {
    technologies[:ruby_on_rails].id => 1,
    technologies[:postgresql].id => 1,
    technologies[:redis].id => 0,
    technologies[:graphql].id => 1
  },
  "jane.smith@company.com" => {
    technologies[:react].id => 1,
    technologies[:javascript].id => 2,
    technologies[:typescript].id => 1,
    technologies[:vuejs].id => 1
  },
  "mike.wilson@company.com" => {
    technologies[:docker].id => 1,
    technologies[:kubernetes].id => 0,
    technologies[:aws].id => 1,
    technologies[:terraform].id => 0
  },
  "sarah.brown@company.com" => {
    technologies[:ruby_on_rails].id => 1,
    technologies[:postgresql].id => 1,
    technologies[:nodejs].id => 0,
    technologies[:graphql].id => 0
  },
  "tom.johnson@company.com" => {
    technologies[:react].id => 0,
    technologies[:javascript].id => 1,
    technologies[:typescript].id => 1,
    technologies[:angular].id => 0
  },
  "lisa.davis@company.com" => {
    technologies[:react].id => 1,
    technologies[:javascript].id => 1,
    technologies[:nodejs].id => 0,
    technologies[:aws].id => 0
  },
  "james.miller@company.com" => {
    technologies[:ruby_on_rails].id => 1,
    technologies[:postgresql].id => 0,
    technologies[:redis].id => 0,
    technologies[:nodejs].id => 0
  },
  "emma.taylor@company.com" => {
    technologies[:ruby_on_rails].id => 2,
    technologies[:postgresql].id => 2,
    technologies[:redis].id => 1,
    technologies[:graphql].id => 1
  }
}

previous_user_skills.each do |user_id, skills|
  skills.each do |tech_id, rating_level|
    next if rating_level == 0

    SkillRating.find_or_create_by!(
      user_id: user_id,
      technology_id: tech_id,
      quarter_id: previous_quarter.id
    ) do |rating|
      rating.rating = rating_level
      rating.status = "approved"
      rating.approved_at = 3.months.ago
      rating.approved_by_id = unit_lead_user.id
      rating.locked = true
    end
  end
end

previous_engineer_skills.each do |email, skills|
  user = User.find_by(email: email)
  next unless user

  skills.each do |tech_id, rating_level|
    next if rating_level == 0

    SkillRating.find_or_create_by!(
      user_id: user.id,
      technology_id: tech_id,
      quarter_id: previous_quarter.id
    ) do |rating|
      rating.team_id = user.team_id
      rating.rating = rating_level
      rating.status = "approved"
      rating.approved_at = 3.months.ago
      rating.approved_by_id = unit_lead_user.id
      rating.locked = true
    end
  end
end

Rails.logger.debug "Creating sample action plans..."

# Create sample action plans
ActionPlan.find_or_create_by!(
  title: "Improve React skills",
  description: "Complete React advanced course and build 2 projects",
  user_id: User.find_by(email: "john.doe@company.com")&.id,
  technology_id: technologies[:react].id,
  quarter_id: current_quarter.id,
  status: "in_progress",
  priority: "high",
  created_by_id: backend_team_lead.id
)

ActionPlan.find_or_create_by!(
  title: "Learn Docker containerization",
  description: "Complete Docker certification and implement in current project",
  user_id: User.find_by(email: "sarah.brown@company.com")&.id,
  technology_id: technologies[:docker].id,
  quarter_id: current_quarter.id,
  status: "active",
  priority: "medium",
  created_by_id: backend_team_lead.id
)

ActionPlan.find_or_create_by!(
  title: "AWS certification preparation",
  description: "Prepare and pass AWS Solutions Architect certification",
  user_id: User.find_by(email: "lisa.davis@company.com")&.id,
  technology_id: technologies[:aws].id,
  quarter_id: current_quarter.id,
  status: "in_progress",
  priority: "high",
  created_by_id: unit_lead_user.id
)

Rails.logger.debug "Seeding completed successfully!"

Rails.logger.debug "\n=== Test Users Created ==="
Rails.logger.debug "Admin: admin@company.com"
Rails.logger.debug "Unit Lead: unit.lead@company.com"
Rails.logger.debug "Backend Team Lead: backend.lead@company.com"
Rails.logger.debug "Frontend Team Lead: frontend.lead@company.com"
Rails.logger.debug "DevOps Team Lead: devops.lead@company.com"
Rails.logger.debug "Engineers: john.doe@company.com, jane.smith@company.com, mike.wilson@company.com, sarah.brown@company.com, tom.johnson@company.com, lisa.davis@company.com, james.miller@company.com, emma.taylor@company.com"
Rails.logger.debug "\nAll users have password: password123"
