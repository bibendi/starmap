#!/usr/bin/env ruby
# Test script to verify model functionality

require_relative 'config/environment'

puts "=== Testing Starmap Models ==="

# Test User model
puts "\n1. Testing User model..."
puts "Total users: #{User.count}"
puts "Users by role:"
User.group(:role).count.each do |role, count|
  puts "  #{role}: #{count}"
end

# Test Team model
puts "\n2. Testing Team model..."
puts "Total teams: #{Team.count}"
Team.all.each do |team|
  puts "  #{team.name} (#{team.unit_name}) - Members: #{team.users.count}"
end

# Test Technology model
puts "\n3. Testing Technology model..."
puts "Total technologies: #{Technology.count}"
puts "Technologies by criticality:"
Technology.group(:criticality).count.each do |criticality, count|
  puts "  #{criticality}: #{count}"
end

# Test Quarter model
puts "\n4. Testing Quarter model..."
puts "Total quarters: #{Quarter.count}"
Quarter.all.each do |quarter|
  puts "  #{quarter.name} - Status: #{quarter.status}"
end

# Test SkillRating model
puts "\n5. Testing SkillRating model..."
puts "Total skill ratings: #{SkillRating.count}"
puts "Ratings by status:"
SkillRating.group(:status).count.each do |status, count|
  puts "  #{status}: #{count}"
end

# Test ActionPlan model
puts "\n6. Testing ActionPlan model..."
puts "Total action plans: #{ActionPlan.count}"
puts "Plans by status:"
ActionPlan.group(:status).count.each do |status, count|
  puts "  #{status}: #{count}"
end

# Test associations
puts "\n7. Testing associations..."
user = User.first
if user
  puts "First user: #{user.display_name_or_full_name}"
  puts "  Team: #{user.team&.name || 'No team'}"
  puts "  Skill ratings: #{user.skill_ratings.count}"
  puts "  Action plans: #{user.action_plans.count}"
end

# Test analytics methods
puts "\n8. Testing analytics methods..."
tech = Technology.first
if tech
  puts "First technology: #{tech.name}"
  puts "  Current experts: #{tech.expert_count}"
  puts "  Average skill level: #{tech.average_skill_level}"
  puts "  Maturity index: #{tech.maturity_index}%"
  puts "  Coverage index: #{tech.coverage_index}%"
end

puts "\n=== All tests completed successfully! ==="
