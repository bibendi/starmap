# Team model for Starmap application
# Represents teams within units with team leads and LDAP group integration
class Team < ApplicationRecord
  # Associations
  belongs_to :team_lead, class_name: 'User', optional: true
  has_many :users, dependent: :nullify
  has_many :skill_ratings, through: :users
  has_many :action_plans, through: :users

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :unit_name, presence: true
  validates :sort_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Callbacks
  before_validation :set_default_sort_order, on: :create

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_unit, ->(unit_name) { where(unit_name: unit_name) }
  scope :ordered, -> { order(:sort_order, :name) }

  # Team leadership helpers
  def has_team_lead?
    team_lead_id.present?
  end

  def team_lead_name
    team_lead&.display_name_or_full_name
  end

  def active_members
    users.active
  end

  def member_count
    active_members.count
  end

  def engineer_count
    active_members.engineers.count
  end

  def team_lead_count
    active_members.team_leads.count
  end

  # Technology expertise analysis
  def technology_expertise
    # Returns hash of technology_id => array of user_ids with rating >= 2
    expertise = {}

    active_members.each do |user|
      user.skill_ratings.joins(:technology)
        .where('skill_ratings.rating >= 2 AND technologies.active = true')
        .each do |rating|
          expertise[rating.technology_id] ||= []
          expertise[rating.technology_id] << user.id
        end
    end

    expertise
  end

  def experts_for_technology(technology)
    # Returns users who have rating >= 2 for this technology
    active_members.joins(:skill_ratings)
      .where(skill_ratings: { technology: technology, rating: 2..3 })
      .distinct
  end

  def single_expert_technologies
    # Returns technologies where there's only one expert (rating >= 2)
    expertise = technology_expertise
    expertise.select { |_tech_id, experts| experts.size == 1 }.keys
  end

  def coverage_gaps
    # Returns technologies where current expert count < target_experts
    gaps = []
    Technology.active.each do |tech|
      current_experts = experts_for_technology(tech).count
      gaps << { technology: tech, current: current_experts, target: tech.target_experts } if current_experts < tech.target_experts
    end
    gaps
  end

  # Risk assessment
  def bus_factor_risks
    # Technologies with only one expert (high risk)
    single_expert_technologies.map do |tech_id|
      technology = Technology.find(tech_id)
      experts = experts_for_technology(technology)
      {
        technology: technology,
        expert_count: experts.count,
        experts: experts,
        risk_level: 'high'
      }
    end
  end

  def maturity_level
    # Calculate team maturity based on skill distribution
    total_ratings = skill_ratings.joins(:technology).where(technologies: { active: true }).count
    return 0 if total_ratings.zero?

    high_skills = skill_ratings.joins(:technology).where(technologies: { active: true }, rating: 3).count
    (high_skills.to_f / total_ratings * 100).round(2)
  end

  # LDAP integration helpers
  def ldap_group_name
    ldap_group_dn&.split(',')&.first&.gsub('cn=', '')
  end

  def sync_with_ldap_group
    # This would sync team members with LDAP group
    # Implementation depends on LDAP server structure
    true
  end

  # Permission helpers
  def can_be_managed_by?(user)
    user.admin? || user.unit_lead?
  end

  def can_be_viewed_by?(user)
    user.admin? || user.unit_lead? || user.team_lead_of?(self)
  end

  private

  def set_default_sort_order
    self.sort_order ||= Team.maximum(:sort_order).to_i + 1
  end
end
